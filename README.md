# fluent-plugin-filter-parse-postfix

Filter Plugin to parse Postfix status line log.

[![Build Status](https://travis-ci.org/winebarrel/fluent-plugin-filter-parse-postfix.svg)](https://travis-ci.org/winebarrel/fluent-plugin-filter-parse-postfix)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-filter-parse-postfix'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-filter-parse-postfix

## Configuration

```apache
<filter>
  @type parse_postfix
  #key message
  #mask true
  #use_log_time false
  #include_hash false
  #salt my_salt
  #sha_algorithm 512 # 1, 224, 256, 384, 512 (default)
  #header_checks_warning false
</filter>
```

## Usage

```sh
$ cat fluent.conf
<source>
  @type forward
</source>

<source>
  @type tail
  path /var/log/maillog
  pos_file /var/log/td-agent/postfix-maillog.pos
  tag postfix.maillog
  format none
</source>

<filter postfix.maillog>
  @type grep
  regexp1 message status=
</filter>

<filter postfix.maillog>
  @type parse_postfix
</filter>

<match postfix.maillog>
  @type stdout
</match>

$ fluentd -c fluent.conf
```

```sh
$ echo '{"message":"Feb 27 09:02:38 MyHOSTNAME postfix/smtp[26490]: 5E31727A35D: to=<bellsouth@myemail.net>, relay=gateway-f1.isp.att.net[204.127.217.17]:25, conn_use=2, delay=0.58, delays=0.11/0.03/0.23/0.20, dsn=2.0.0, status=sent (250 ok ; id=en4req0070M63004172202102)"}' | fluent-cat postfix.maillog
#=> 2015-12-22 02:02:22 +0900 postfix.maillog: {"time":"Feb 27 09:02:38","hostname":"MyHOSTNAME","process":"postfix/smtp[26490]","queue_id":"5E31727A35D","to":"<*********@myemail.net>","domain":"myemail.net","relay":"gateway-f1.isp.att.net[204.127.217.17]:25","conn_use":2,delay":0.58,"delays":"0.11/0.03/0.23/0.20","dsn":"2.0.0","status":"sent","status_detail":"(250 ok ; id=en4req0070M63004172202102)"}
```

## Output

see https://github.com/winebarrel/postfix_status_line

```json
{
  "time":"Feb 27 09:02:38",
  "hostname":"MyHOSTNAME",
  "process":"postfix/smtp[26490]",
  "queue_id":"5E31727A35D",
  "to":"*********@myemail.net",
  "domain":"myemail.net",
  "relay":"gateway-f1.isp.att.net[204.127.217.17]:25",
  "conn_use":2,
  "delay":0.58,
  "delays":"0.11/0.03/0.23/0.20",
  "dsn":"2.0.0",
  "status":"sent",
  "status_detail":"(250 ok ; id=en4req0070M63004172202102)"
}
```

### Parse Header Checks Warning

```sh
$ cat fluent.conf
...
<filter postfix.maillog>
  @type grep
  regexp1 message warning: header
</filter>

<filter postfix.maillog>
  @type parse_postfix
  header_checks_warning true
</filter>
...

$ fluentd -c fluent.conf
```

```sh
$ echo '{"message":"Mar  4 14:44:19 P788 postfix/cleanup[7426]: E80A9DF6F7E: warning: header Subject: test from local; from=<sugawara@P788.local> to=<sgwr_dts@yahoo.co.jp>"}' | fluent-cat postfix.maillog
#=> 2017-03-04 18:26:46.146399000 +0900 postfix.maillog: {
#     "time":"Mar  4 14:44:19","hostname":"P788",
#     "process":"postfix/cleanup[7426]",
#     "queue_id":"E80A9DF6F7E",
#     "to":"********@yahoo.co.jp",
#     "domain":"yahoo.co.jp",
#     "from":"********@P788.local",
#     "Subject":"test from local;"}
```
