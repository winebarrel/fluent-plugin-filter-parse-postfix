describe Fluent::ParsePostfixFilter do
  let(:fluentd_conf) { {} }
  let(:driver) { create_driver(fluentd_conf) }
  let(:today) { Time.parse('2015/05/24 18:30 UTC') }
  let(:time) { today.to_i }

  let(:records) do
    [
      {"message"=>"Feb 27 09:02:37 MyHOSTNAME postfix/smtp[26490]: D53A72713E5: to=<myemail@bellsouth.net>, relay=gateway-f1.isp.att.net[204.127.217.16]:25, delay=0.57, delays=0.11/0.03/0.23/0.19, dsn=2.0.0, status=sent (250 ok ; id=20120227140036M0700qer4ne)"},
      {"message"=>"Feb 27 09:02:38 MyHOSTNAME postfix/smtp[26490]: 5E31727A35D: to=<bellsouth@myemail.net>, relay=gateway-f1.isp.att.net[204.127.217.17]:25, delay=0.58, delays=0.11/0.03/0.23/0.20, dsn=2.0.0, status=sent (250 ok ; id=en4req0070M63004172202102)"},
    ]
  end

  before do
    Timecop.freeze(today)
  end

  subject do
    records.each do |record|
      driver.emit(record, time)
    end

    driver.run
    driver.emits
  end

  context 'with mask' do
    it do
      is_expected.to eq [
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:37", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"D53A72713E5", "to"=>"<*******@bellsouth.net>", "domain"=>"bellsouth.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.16]:25", "delay"=>0.57, "delays"=>"0.11/0.03/0.23/0.19", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=20120227140036M0700qer4ne)"}],
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "to"=>"<*********@myemail.net>", "domain"=>"myemail.net",   "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)"}],
      ]
    end
  end

  context 'when use log time' do
    let(:fluentd_conf) do
      {use_log_time: true}
    end

    it do
      is_expected.to eq [
        ["test.default", 1425027757, {"time"=>"Feb 27 09:02:37", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"D53A72713E5", "to"=>"<*******@bellsouth.net>", "domain"=>"bellsouth.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.16]:25", "delay"=>0.57, "delays"=>"0.11/0.03/0.23/0.19", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=20120227140036M0700qer4ne)"}],
        ["test.default", 1425027758, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "to"=>"<*********@myemail.net>", "domain"=>"myemail.net",   "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)"}],
      ]
    end
  end

  context 'without mask' do
    let(:fluentd_conf) do
      {mask: false}
    end

    it do
      is_expected.to eq [
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:37", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"D53A72713E5", "to"=>"<myemail@bellsouth.net>", "domain"=>"bellsouth.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.16]:25", "delay"=>0.57, "delays"=>"0.11/0.03/0.23/0.19", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=20120227140036M0700qer4ne)"}],
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "to"=>"<bellsouth@myemail.net>", "domain"=>"myemail.net",   "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)"}],
      ]
    end
  end

  context 'when cannot parse' do
    let(:records) do
      [
        {"message"=>"Feb 27 09:02:37 MyHOSTNAME postfix/smtp[26490] x D53A72713E5: to=<myemail@bellsouth.net>, relay=gateway-f1.isp.att.net[204.127.217.16]:25, delay=0.57, delays=0.11/0.03/0.23/0.19, dsn=2.0.0, status=sent (250 ok ; id=20120227140036M0700qer4ne)"},
        {"message"=>"Feb 27 09:02:38 MyHOSTNAME postfix/smtp[26490]: 5E31727A35D: to=<bellsouth@myemail.net>, relay=gateway-f1.isp.att.net[204.127.217.17]:25, delay=0.58, delays=0.11/0.03/0.23/0.20, dsn=2.0.0, status=sent (250 ok ; id=en4req0070M63004172202102)"},
      ]
    end

    before do
      expect(driver.instance.log).to receive(:warn).with('Could not parse a postfix log: Feb 27 09:02:37 MyHOSTNAME postfix/smtp[26490] x D53A72713E5: to=<myemail@bellsouth.net>, relay=gateway-f1.isp.att.net[204.127.217.16]:25, delay=0.57, delays=0.11/0.03/0.23/0.19, dsn=2.0.0, status=sent (250 ok ; id=20120227140036M0700qer4ne)')
    end

    it do
      is_expected.to eq [
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "to"=>"<*********@myemail.net>", "domain"=>"myemail.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)", "status"=>"sent"}],
      ]
    end
  end

  context 'when expired' do
    let(:records) do
      [
        {"message"=>"May 29 19:21:17 testserver postfix/qmgr[4833]: 9D7FE1D0051: from=<root@test.hogehoge>, status=expired, returned to sender"},
        {"message"=>"Feb 27 09:02:38 MyHOSTNAME postfix/smtp[26490]: 5E31727A35D: to=<bellsouth@myemail.net>, relay=gateway-f1.isp.att.net[204.127.217.17]:25, delay=0.58, delays=0.11/0.03/0.23/0.20, dsn=2.0.0, status=sent (250 ok ; id=en4req0070M63004172202102)"},
      ]
    end

    it do
      is_expected.to eq [
        ["test.default", 1432492200, {"time"=>"May 29 19:21:17", "hostname"=>"testserver", "process"=>"postfix/qmgr[4833]", "queue_id"=>"9D7FE1D0051", "from"=>"<****@test.hogehoge>", "status_detail"=>" returned to sender", "status"=>"expired"}],
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "to"=>"<*********@myemail.net>", "domain"=>"myemail.net",   "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)"}],
      ]
    end
  end
end
