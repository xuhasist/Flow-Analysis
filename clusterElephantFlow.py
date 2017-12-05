import os
import time
import logging
import datetime
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from subprocess import Popen, PIPE, STDOUT

logging.basicConfig(level=logging.DEBUG,  
                    format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',  
                    datefmt='%a, %d %b %Y %H:%M:%S',  
                    filename='/tmp/test.log',  
                    filemode='w')  

def main():
    pd.set_option('expand_frame_repr', False)

    timeInterval_set = [(datetime.datetime.strptime('00:26', "%H:%M"), datetime.datetime.strptime('00:48', "%H:%M")), \
    (datetime.datetime.strptime('00:48', "%H:%M"), datetime.datetime.strptime('01:10', "%H:%M")), \
    (datetime.datetime.strptime('01:10', "%H:%M"), datetime.datetime.strptime('01:32', "%H:%M"))]

    os.system('javac Tree.java')
    elephantFlowIndex = Popen(['java', 'Tree'], stdout=PIPE, stderr=STDOUT).stdout.read().split(',')

    df = pd.read_csv('univ1/csv/univ1_all.csv')
    elephantFlow = df.iloc[elephantFlowIndex]

    del elephantFlowIndex
    del df

    elephantFlow = processElephantFlow(elephantFlow)

    flow_start_time = elephantFlow['start_date_time'].dt.hour*3600 + elephantFlow['start_date_time'].dt.minute*60
    flow_end_time = elephantFlow['end_date_time'].dt.hour*3600 + elephantFlow['end_date_time'].dt.minute*60

    result = findIpSet(elephantFlow)
    ip_df = result[0]
    ip_list = result[1]

    ip_df['edgeSw'] = -1
    
    del result
    
    k = 6
    edgeSw = (k/2) * k
    host = len(ip_list)

    edgeSw_host = []

    result = calculateHostAtEdgeSw(k, edgeSw, host, edgeSw_host, ip_df)
    edgeSw_host = result[0]
    ip_df = result[1]

    del result

    i = 0
    for x in range(0, edgeSw):
        mask = elephantFlow.srcip.isin(ip_list[i:i+edgeSw_host[x]])
        elephantFlow_filter = elephantFlow[mask]

        time_group = [0, 0, 0]
        for y, interval in enumerate(timeInterval_set):
            time_group[y] = groupTime(interval, elephantFlow_filter, flow_start_time, flow_end_time)
            
        for y, group in enumerate(time_group):
            remain_flow = groupPrefix(3, ['srcip_1', 'srcip_2', 'srcip_3', 'dstip_1', 'dstip_2', 'dstip_3'], group, \
            elephantFlow, ip_df, y)
            remain_flow = groupPrefix(2, ['srcip_1', 'srcip_2', 'dstip_1', 'dstip_2'],  remain_flow, elephantFlow, ip_df, y)
            remain_flow = groupPrefix(1, ['srcip_1', 'dstip_1'], remain_flow, elephantFlow, ip_df, y)

        i = i + edgeSw_host[x]

    elephantFlow.drop(['srcip_1', 'srcip_2', 'srcip_3', 'srcip_4', 'dstip_1', 'dstip_2', 'dstip_3', 'dstip_4'], \
    axis=1, inplace=True)

    cols = ['start_date_time', 'end_date_time', 'srcip', 'dstip', 'srcport', 'dstport', 'protocol', 'bytes', 'group']
    elephantFlow = elephantFlow[cols]

    elephantFlow.to_csv('elephantFlow_' + str(k) + '.csv', index=False, header=False)
  
def groupPrefix(n, prefix_list, flow, elephantFlow, ip_df, x):
    subset = flow[prefix_list]
    ip_set = set(tuple(x) for x in subset.values)
    del subset

    remain_flow = pd.DataFrame([], columns=['start_date_time', 'end_date_time', 'srcip', 'srcip_1', 'srcip_2', \
    'srcip_3', 'srcip_4', 'dstip', 'dstip_1', 'dstip_2', 'dstip_3', 'dstip_4', 'srcport', 'dstport', 'protocol', \
    'transferred_bytes'])
    
    for ip in ip_set:
        if n == 1:
            group = flow[(flow['srcip_1'] == ip[0]) & (flow['dstip_1'] == ip[1])]
        elif n == 2:
            group = flow[(flow['srcip_1'] == ip[0]) & (flow['srcip_2'] == ip[1]) & \
            (flow['dstip_1'] == ip[2]) & (flow['dstip_2'] == ip[3])]
        elif n == 3:
            group = flow[(flow['srcip_1'] == ip[0]) & (flow['srcip_2'] == ip[1]) & \
            (flow['srcip_3'] == ip[2]) & (flow['dstip_1'] == ip[3]) & \
            (flow['dstip_2'] == ip[4]) & (flow['dstip_3'] == ip[5])]

        if len(group) == 1: #or len(group) > threshold:
            remain_flow = remain_flow.append(group)
        elif len((ip_df[ip_df['ip'].isin(group['dstip'].drop_duplicates().tolist())]['edgeSw'].drop_duplicates()).tolist()) \
        >= 2:
            pass
        else:
            elephantFlow.loc[group.index.tolist(), 'group'] = n

    return remain_flow


def groupTime(interval, flow, flow_start_time, flow_end_time):
    start = interval[0].hour*3600 + interval[0].minute*60
    end = interval[1].hour*3600 + interval[1].minute*60

    group = flow[((flow_start_time >= start) & (flow_start_time < end)) | ((flow_end_time >= start) & (flow_end_time < end))]

    return group


def calculateHostAtEdgeSw(k, edgeSw, host, edgeSw_host, ip_df):  
    pod_host = int(round(float(host)/float(k)))

    host_at_pod = []
    host_at_pod[0:k-1] = [pod_host] * k
    host_at_pod[-1] = host - pod_host * (k-1)
    
    i = 0
    for x in range(0, edgeSw, (k/2)):
        sw_host = int(round(host_at_pod[i] / (float(k)/2.0)))

        host_at_sw = []
        host_at_sw[0:(k/2)] = [sw_host] * (k/2)
        host_at_sw[-1] = host_at_pod[i] - sw_host * ((k/2)-1)

        edgeSw_host[x:x+(k/2)] = host_at_sw[0:(k/2)]
        i = i + 1

    i = 0
    for x in range(0, edgeSw):
        ip_df.loc[range(i, i+edgeSw_host[x]), 'edgeSw'] = x
        i = i + edgeSw_host[x]

    ip_df.drop(['ip_1', 'ip_2', 'ip_3', 'ip_4'], axis=1, inplace=True)

    return [edgeSw_host, ip_df]


def processElephantFlow(elephantFlow):
    elephantFlow = elephantFlow.reset_index(drop=True)

    elephantFlow['srcip_1'], elephantFlow['srcip_2'], elephantFlow['srcip_3'], elephantFlow['srcip_4'] = \
    zip(*elephantFlow['srcip'].map(lambda x: x.split('.')))
    elephantFlow['dstip_1'], elephantFlow['dstip_2'], elephantFlow['dstip_3'], elephantFlow['dstip_4'] = \
    zip(*elephantFlow['dstip'].map(lambda x: x.split('.')))

    elephantFlow.rename(columns={'transferred_bytes': 'bytes'}, inplace=True)

    cols = ['start_date_time', 'end_date_time', 'srcip', 'srcip_1', 'srcip_2', 'srcip_3', 'srcip_4', \
    'dstip', 'dstip_1', 'dstip_2', 'dstip_3', 'dstip_4', 'srcport', 'dstport', 'protocol', 'bytes']
    elephantFlow = elephantFlow[cols]

    elephantFlow['start_date_time'] = pd.to_datetime(elephantFlow['start_date_time'])
    elephantFlow['end_date_time'] = pd.to_datetime(elephantFlow['end_date_time'])

    elephantFlow['group'] = -1
    elephantFlow['length'] = -1

    return elephantFlow


def findIpSet(elephantFlow):
    ip_df = pd.DataFrame([], columns=['ip'])

    src_ip = elephantFlow['srcip'].tolist()
    dst_ip = elephantFlow['dstip'].tolist()

    ip_df['ip'] = src_ip + dst_ip
    ip_df = ip_df.drop_duplicates()

    ip_df['ip_1'], ip_df['ip_2'], ip_df['ip_3'], ip_df['ip_4'] = zip(*ip_df['ip'].map(lambda x: x.split('.')))

    ip_df['ip_1'] = ip_df['ip_1'].astype(int)
    ip_df['ip_2'] = ip_df['ip_2'].astype(int)
    ip_df['ip_3'] = ip_df['ip_3'].astype(int)
    ip_df['ip_4'] = ip_df['ip_4'].astype(int)

    ip_df = ip_df.sort_values(['ip_1', 'ip_2', 'ip_3', 'ip_4'])
    ip_df = ip_df.reset_index(drop=True)

    ip_list = ip_df['ip'].tolist()

    return [ip_df, ip_list]
    

if __name__ == '__main__':
    print time.strftime('%Y-%m-%d %H:%M:%S')
    main()
    print time.strftime('%Y-%m-%d %H:%M:%S')
