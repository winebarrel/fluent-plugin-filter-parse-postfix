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
