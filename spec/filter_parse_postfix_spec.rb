describe Fluent::ParsePostfixFilter do
  let(:fluentd_conf) { {} }
  let(:driver) { create_driver(fluentd_conf) }
  let(:today) { Time.parse('2015/05/24 18:30 UTC') }
  let(:time) { today.to_i }
  let!(:parsed_time) { Time.parse('02/27 09:02:37 +0000').to_i }

  let(:records) do
    [
      {"message"=>"Feb 27 09:02:37 MyHOSTNAME postfix/smtp[26490]: D53A72713E5: to=<myemail@bellsouth.net>, relay=gateway-f1.isp.att.net[204.127.217.16]:25, conn_use=2, delay=0.57, delays=0.11/0.03/0.23/0.19, dsn=2.0.0, status=sent (250 ok ; id=20120227140036M0700qer4ne)"},
      {"message"=>"Feb 27 09:02:38 MyHOSTNAME postfix/smtp[26490]: 5E31727A35D: to=<bellsouth@myemail.net>, relay=gateway-f1.isp.att.net[204.127.217.17]:25, conn_use=3, delay=0.58, delays=0.11/0.03/0.23/0.20, dsn=2.0.0, status=sent (250 ok ; id=en4req0070M63004172202102)"},
    ]
  end

  before do
    Timecop.freeze(today)
  end

  after do
    Timecop.return
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
      is_expected.to match_array [
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:37", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"D53A72713E5", "to"=>"*******@bellsouth.net", "domain"=>"bellsouth.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.16]:25", "conn_use"=>2, "delay"=>0.57, "delays"=>"0.11/0.03/0.23/0.19", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=20120227140036M0700qer4ne)"}],
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "to"=>"*********@myemail.net", "domain"=>"myemail.net",   "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "conn_use"=>3, "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)"}],
      ]
    end
  end

  context 'when use log time' do
    let(:fluentd_conf) do
      {use_log_time: true}
    end

    it do
      is_expected.to match_array [
        ["test.default", parsed_time    , {"time"=>"Feb 27 09:02:37", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"D53A72713E5", "to"=>"*******@bellsouth.net", "domain"=>"bellsouth.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.16]:25", "conn_use"=>2, "delay"=>0.57, "delays"=>"0.11/0.03/0.23/0.19", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=20120227140036M0700qer4ne)"}],
        ["test.default", parsed_time + 1, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "to"=>"*********@myemail.net", "domain"=>"myemail.net",   "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "conn_use"=>3, "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)"}],
      ]
    end
  end

  context 'without mask' do
    let(:fluentd_conf) do
      {mask: false}
    end

    it do
      is_expected.to match_array [
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:37", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"D53A72713E5", "to"=>"myemail@bellsouth.net", "domain"=>"bellsouth.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.16]:25", "conn_use"=>2, "delay"=>0.57, "delays"=>"0.11/0.03/0.23/0.19", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=20120227140036M0700qer4ne)"}],
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "to"=>"bellsouth@myemail.net", "domain"=>"myemail.net",   "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "conn_use"=>3, "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status"=>"sent", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)"}],
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
      expect(driver.instance.log).to receive(:warn).with('cannot parse a postfix log: Feb 27 09:02:37 MyHOSTNAME postfix/smtp[26490] x D53A72713E5: to=<myemail@bellsouth.net>, relay=gateway-f1.isp.att.net[204.127.217.16]:25, delay=0.57, delays=0.11/0.03/0.23/0.19, dsn=2.0.0, status=sent (250 ok ; id=20120227140036M0700qer4ne)')
    end

    it do
      is_expected.to match_array [
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "to"=>"*********@myemail.net", "domain"=>"myemail.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)", "status"=>"sent"}],
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
      is_expected.to match_array [
        ["test.default", 1432492200, {"time"=>"May 29 19:21:17", "hostname"=>"testserver", "process"=>"postfix/qmgr[4833]", "queue_id"=>"9D7FE1D0051", "from"=>"****@test.hogehoge", "status_detail"=>" returned to sender", "status"=>"expired"}],
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "to"=>"*********@myemail.net", "domain"=>"myemail.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)", "status"=>"sent"}],
      ]
    end
  end

  context 'include hash' do
    let(:fluentd_conf) do
      {include_hash: true, salt: 'my_salt'}
    end

    it do
      is_expected.to match_array [
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:37", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"D53A72713E5", "hash"=>"f275e00cdebc8ae2e85e632cd9ad1e795c631f10c91058f880693ba1c4f3c28029e642ebb2b73050bd0e0123d8a8a4513946c5832f12f14ab2338482bd703799", "to"=>"*******@bellsouth.net", "domain"=>"bellsouth.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.16]:25", "conn_use"=>2, "delay"=>0.57, "delays"=>"0.11/0.03/0.23/0.19", "dsn"=>"2.0.0", "status_detail"=>"(250 ok ; id=20120227140036M0700qer4ne)", "status"=>"sent"}],
        ["test.default", 1432492200, {"time"=>"Feb 27 09:02:38", "hostname"=>"MyHOSTNAME", "process"=>"postfix/smtp[26490]", "queue_id"=>"5E31727A35D", "hash"=>"c56ab6964ac53f423f849ddd8befd65fbd94db3b3fbe2ef018d933ec066e73e1666eea05c345d66fc2b7eabf7208019fc8bd3fa705d17c275d5859131a49cccc", "to"=>"*********@myemail.net", "domain"=>"myemail.net", "relay"=>"gateway-f1.isp.att.net[204.127.217.17]:25", "conn_use"=>3, "delay"=>0.58, "delays"=>"0.11/0.03/0.23/0.20", "dsn"=>"2.0.0", "status_detail"=>"(250 ok ; id=en4req0070M63004172202102)", "status"=>"sent"}],
      ]
    end
  end

  context 'when error happen' do
    before do
      expect(PostfixStatusLine).to receive(:parse).and_raise('unknown error')
      expect(PostfixStatusLine).to receive(:parse).and_return('parse' => 'OK')

      expect(driver.instance.log).to receive(:warn).with(
        "failed to parse a postfix log: Feb 27 09:02:37 MyHOSTNAME postfix/smtp[26490]: D53A72713E5: to=<myemail@bellsouth.net>, relay=gateway-f1.isp.att.net[204.127.217.16]:25, conn_use=2, delay=0.57, delays=0.11/0.03/0.23/0.19, dsn=2.0.0, status=sent (250 ok ; id=20120227140036M0700qer4ne)",
        {:error_class=>RuntimeError, :error=>"unknown error"})
      expect(driver.instance.log).to receive(:warn_backtrace)
    end

    it do
      is_expected.to match_array [
        ["test.default", 1432492200, {"parse"=>"OK"}]
      ]
    end
  end
end
