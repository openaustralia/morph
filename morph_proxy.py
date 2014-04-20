# Run this with mitmdump -q -s morph_proxy.py

def request(context, flow):
  # print out all the basic information to determine what request is being made
  # coming from which container
  # print flow.request.method
  # print flow.request.host
  # print flow.request.path
  # print flow.request.scheme
  # print flow.request.client_conn.address[0]
  # print "***"
  #text = flow.request.method + " " + flow.request.scheme + "://" + flow.request.host + flow.request.path + " FROM " + flow.request.client_conn
  text = flow.request.method + " " + flow.request.scheme + "://" + flow.request.host + flow.request.path + " FROM " + flow.request.client_conn.address[0]
  print text
  # print "***"
