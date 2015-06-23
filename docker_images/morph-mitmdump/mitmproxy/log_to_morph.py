# Run this with dotenv mitmdump -q -a -s mitmproxy/log_to_morph.py --confdir mitmproxy

import urllib
import os

from libmproxy.script import concurrent

@concurrent
def response(context, flow):
  url = os.environ['MORPH_URL'] + "/connection_logs"
  params = urllib.urlencode({
  	'ip_address': flow.client_conn.address.host,
  	'method': flow.request.method,
  	'scheme': flow.request.scheme,
    'host': flow.request.pretty_host(hostheader=True),
    'path': flow.request.path,
    'request_size': len(flow.request.content),
    'response_size': len(flow.response.content),
    'response_code': flow.response.code,
    'key': os.environ['MITMPROXY_SECRET']
  })
  try:
    s = urllib.urlopen(url, params)
    s.close()
  # If we can't contact the morph.io server still handle this request.
  # If we let this exception pass up the chain the request would get dropped
  except IOError, e:
    print "Error contacting morph.io server:", e
