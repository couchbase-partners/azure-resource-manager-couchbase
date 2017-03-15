import os
import time

debug = 1

def execute(args):
    global debug
    print " \n"
    print " the command is ", args
    print " \n"
    process = os.popen(args)
    preprocessed = process.read()
    if debug:
        print preprocessed
    process.close()

def setup_uname_pass(username, password, current_ip):
   print 'setup username password for {0}'.format(current_ip)
   args =  "curl -v -X POST \
http://{0}:8091/settings/web -d 'password={1}&username={2}&port=SAME'".format(current_ip, password, username)
   execute(args)

def setup_datapath(current_ip, datapath ):
    print 'setup datapath for {0}'.format(current_ip)
    args = "curl -v http://{0}:8091/nodes/self/controller/settings -d path={1}".format(current_ip, datapath)
    execute(args)

def setup_memquota(uname, passwd, current_ip, index_quota, data_quota):
    print 'setup memQuota for {0}'.format(current_ip)
    args = "curl -v -u {0}:{1}  -X POST http://{2}:8091/pools/default -d memoryQuota={3} -d indexMemoryQuota={4}".format(uname, passwd, current_ip, data_quota, index_quota)
    execute(args)

def setup_service(username, password, current_ip, service):
    print 'setup service for {0}'.format(current_ip)
    args="curl -v -u {0}:{1} -X POST \
    http://{2}:8091/node/controller/setupServices -d 'services={3}'".format(username, password, current_ip, service)
    execute(args)


def add_node( username, password, master_ip, slave_ip, service):
    print 'add node for {0} to {1}'.format(slave_ip, master_ip)
    args = 'curl -u {0}:{1} {2}:8091/controller/addNode' \
                ' -d "hostname={3}&user={4}&password={5}" -d "services={6}"'.format(username, password,
                                                                                    master_ip, slave_ip, username, password, service)
    execute(args)
    time.sleep(30)


def rebalance(username, password, master, slaves):
    print 'performing rebalance operation'
    tmp_slaves = slaves
    tmp_slaves.append(master)
    known_nodes = ','.join([ 'ns_1@' + s for s in tmp_slaves])
    args = "curl -v -u {0}:{1} -X POST 'http://{2}:8091/controller/rebalance' \
-d 'knownNodes={3}'".format(username, password, master,known_nodes)
    execute(args)

    args = "/opt/couchbase/bin/couchbase-cli rebalance -c {0}:8091 -u {1} -p {2}".format(master, username, password)
    execute(args)


def rename(master, username, password):
    args = "curl -v -X POST -u  {0}:{1}  http://{2}:8091/node/controller/rename -d hostname={3}".\
        format(username, password, master, master)
    execute(args)

def read_file():
    instance = {}
    ips = []
    fo = open("/tmp/instances.txt", "r")
    for line in fo:
        value = line.split(',')
        option = value[0].strip()
        data = value[1].strip()
        if option == "slave":
            ips.append(data)
        else:
            instance[option] = data
    instance["slave"] = ips
    fo.close()
    return instance

def main():
    instance = read_file()
    print instance
    master_ip = instance["master"]
    uname = instance["USER_NAME"]
    passwd = instance["PASSWORD"]
    datapath = instance["DATA_PATH"]
    index_quota = instance["INDEX_QUOTA"]
    data_quota = instance["DATA_QUOTA"]
    
    setup_datapath(master_ip, datapath)
    setup_service(uname, passwd, master_ip, 'index,kv,n1ql')
    setup_uname_pass(uname, passwd, master_ip)
    setup_memquota(uname, passwd, master_ip, index_quota, data_quota)
    rename(master_ip, uname, passwd)

    for ip in instance["slave"]:
        setup_datapath(ip, datapath)
        setup_uname_pass(uname, passwd, ip)
        rename(ip, uname, passwd)
        add_node(uname, passwd, master_ip, ip, 'index,kv,n1ql')
        add_node(uname, passwd, master_ip, ip, 'index,kv,n1ql')
        setup_memquota(uname, passwd, ip, index_quota, data_quota)

    rebalance(uname, passwd, master_ip,instance["slave"])

main()