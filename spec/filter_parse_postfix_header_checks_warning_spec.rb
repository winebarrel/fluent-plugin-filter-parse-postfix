describe Fluent::ParsePostfixFilter do
  let(:fluentd_conf) { {} }
  let(:driver) { create_driver(fluentd_conf) }
  let(:today) { Time.parse('2015/05/24 18:30 UTC') }
  let(:time) { today.to_i }
  let!(:parsed_time) { Time.parse('02/27 09:02:37 +0000').to_i }

  let(:records) do
    [
      {"message"=>"Mar  4 14:44:19 P788 postfix/cleanup[7426]: E80A9DF6F7E: warning: header To: sgwr_dts@yahoo.co.jp from local; from=<sugawara@P788.local> to=<sgwr_dts@yahoo.co.jp>"},
      {"message"=>"Mar  4 14:44:19 P788 postfix/cleanup[7426]: E80A9DF6F7E: warning: header Subject: test from local; from=<sugawara@P788.local> to=<sgwr_dts@yahoo.co.jp>"},
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

  context 'when parse_header_checks_warning mask' do
    let(:fluentd_conf) do
      {header_checks_warning: true}
    end

    it do
      is_expected.to match_array [
        ["test.default", 1432492200, {"time"=>"Mar  4 14:44:19", "hostname"=>"P788", "process"=>"postfix/cleanup[7426]", "queue_id"=>"E80A9DF6F7E", "to"=>"********@yahoo.co.jp", "domain"=>"yahoo.co.jp", "from"=>"********@P788.local", "To"=>"********@yahoo.co.jp from local;"}],
        ["test.default", 1432492200, {"time"=>"Mar  4 14:44:19", "hostname"=>"P788", "process"=>"postfix/cleanup[7426]", "queue_id"=>"E80A9DF6F7E", "to"=>"********@yahoo.co.jp", "domain"=>"yahoo.co.jp", "from"=>"********@P788.local", "Subject"=>"test from local;"}],
      ]
    end
  end
end
