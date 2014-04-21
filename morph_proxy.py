# Run this with mitmdump -q -s morph_proxy.py

def response(context, flow):
  text = flow.request.method + " " + flow.request.scheme + "://" + flow.request.host + flow.request.path + " FROM " + flow.request.client_conn.address[0] + " REQUEST SIZE " + str(len(flow.request.content)) + " RESPONSE SIZE " + str(len(flow.response.content))
  print text
