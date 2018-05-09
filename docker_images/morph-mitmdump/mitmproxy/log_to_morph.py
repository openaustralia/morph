# Run this with dotenv mitmdump -q -a -s mitmproxy/log_to_morph.py --confdir mitmproxy

import urllib
import os

# Doing this to be able to handle running this under mitmproxy 0.12 and 0.17.1
try:
    from mitmproxy.script import concurrent
except ImportError:
    pass

try:
    from libmproxy.script import concurrent
except ImportError:
    pass

@concurrent
def response(context, flow):
  for env in ['MORPH_URL', 'MITMPROXY_SECRET']:
    if not env in os.environ:
      print("WARNING:", env, "is not set!")
      return

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
  except IOError as e:
    print("Error contacting morph.io server:", e)
