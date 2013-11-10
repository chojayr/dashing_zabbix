require 'zabby'
require 'json'
require 'active_support/core_ext/numeric/time'

  swarn = []
  savrg = []
  shgh = []
  sdis = []

  twarn = 0
  tavrg = 0
  thgh = 0
  tdis = 0

  lav_warn = 0
  lav_avrg = 0
  lav_hgh = 0
  lav_dis = 0

SCHEDULER.every '13s' do

  serv = Zabby.init do
    set :server => "http://example.zabbix.com/zabbix"
    set :user => "username"
    set :password => "password"
    login
  end

  env = serv.run { Zabby::Trigger.get "filter" => { "priority" => [ 2, 3, 4, 5 ] }, "output" => "extend", "only_true" => "true", "monitored" => 1, "withUnacknowledgedEvents" => 1, "skipDependent" => 1, "expandData" => "host" } 
  
  pas = JSON.parse(env.to_json)
  
  pas.each do |res|
  
    prio = res["priority"]
    lstchnge = res["lastchange"]
    hostnme = res["hostname"]
    alertime = Time.at(lstchnge.to_i)
    
    #adjust the pref. time 
    timelapse = Time.now - 1.hours
    
    if alertime >= timelapse 
      case prio
        when '2' then
          swarn << hostnme
        when '3' then
          savrg << hostnme
        when '4' then
          shgh << hostnme
        when '5' then
          sdis << hostnme
      end
    end
  end

  lav_warn = twarn
  lav_avrg = tavrg
  lav_hgh = thgh
  lav_dis = tdis

  twarn = swarn.count 
  tavrg = savrg.count 
  thgh = shgh.count 
  tdis = sdis.count 

  warn = twarn - lav_warn 
  avrg = tavrg - lav_avrg
  hgh = thgh - lav_hgh 
  dis = tdis - lav_dis 

  if warn > 0 then warnstats = "warn" else warnstats = "ok" end
  if avrg > 0 then avrgstats = "average" else avrgstats = "ok" end
  if hgh > 0 then hghstats = "high" else hghstats = "ok" end
  if dis > 0 then disstats = "disaster" else disstats = "ok" end
  send_event( 'outwarn', { current: warn, last: lav_warn, status: warnstats } )
  send_event( 'outavrg', { current: avrg, last: lav_avrg, status: avrgstats } )
  send_event( 'outhigh', { current: hgh, last: lav_hgh, status: hghstats  } )
  send_event( 'outdis', { current: dis, last: lav_dis, status: disstats  } )
  
end

