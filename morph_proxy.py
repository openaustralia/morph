# Run this with mitmdump -q -s morph_proxy.py

import urllib

def response(context, flow):
  text = flow.request.method + " " + flow.request.scheme + "://" + flow.request.host + flow.request.path + " FROM " + flow.request.client_conn.address[0] + " REQUEST SIZE " + str(len(flow.request.content)) + " RESPONSE SIZE " + str(len(flow.response.content))
  print text
  url = "http://localhost:3000/connection_logs"
  params = urllib.urlencode({
  	'ip_address': flow.request.client_conn.address[0],
  	'method': flow.request.method,
  	'scheme': flow.request.scheme,
    'host': flow.request.host,
    'path': flow.request.path,
    'request_size': len(flow.request.content),
    'response_size': len(flow.response.content)
  })
  u = urllib.urlopen(url, params)
  data = u.read()
  print data
