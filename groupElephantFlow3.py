import os
import time
import datetime
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from subprocess import Popen, PIPE, STDOUT

print 'program start at ' + str(time.strftime('%Y-%m-%d %H:%M:%S'))
print

timeInterval_set = [(datetime.datetime.strptime('00:26', "%H:%M"), datetime.datetime.strptime('00:48', "%H:%M")), \
(datetime.datetime.strptime('00:48', "%H:%M"), datetime.datetime.strptime('01:10', "%H:%M")), \
(datetime.datetime.strptime('01:10', "%H:%M"), datetime.datetime.strptime('01:32', "%H:%M"))]   

threshold = 190

df_allPkt = pd.read_csv('univ1/univ1_filter.csv')

df_allPkt['DateTime'] = pd.to_datetime(df_allPkt['DateTime'])
df_allPkt['Protocol'] = np.where(df_allPkt['Protocol']==6, 'TCP', 'UDP')

allPkt_time = df_allPkt['DateTime'].dt.hour*3600 + df_allPkt['DateTime'].dt.minute*60 + df_allPkt['DateTime'].dt.second

os.system('javac Tree.java')
elephantFlowIndex = Popen(['java', 'Tree'], stdout=PIPE, stderr=STDOUT).stdout.read().split(',')

df = pd.read_csv('univ1/csv/univ1_all.csv')
elephantFlow = df.iloc[elephantFlowIndex]
elephantFlow = elephantFlow.reset_index(drop=True)

del elephantFlowIndex
del df


def groupTime(interval, flow, flow_start_time, flow_end_time):
    start = interval[0].hour*3600 + interval[0].minute*60
    end = interval[1].hour*3600 + interval[1].minute*60

    group = flow[((flow_start_time >= start) & (flow_start_time < end)) | \
    ((flow_end_time >= start) & (flow_end_time < end))]

    slot_num = (end - start) / 60

    return [group, slot_num]


def groupPrefix(n, prefix_list, flow, x, slot_num, slot_size):
    subset = flow[prefix_list]
    ip_set = set(tuple(x) for x in subset.values)
    del subset
    
    remain_flow = pd.DataFrame([], columns=['start_date_time', 'end_date_time', 'srcip', 'srcip_1', 'srcip_2', \
    'srcip_3', 'srcip_4', 'dstip', 'dstip_1', 'dstip_2', 'dstip_3', 'dstip_4', 'srcport', 'dstport', 'protocol'])

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
        elif n == 4:
            group = flow[(flow['srcip_1'] == ip[0]) & (flow['srcip_2'] == ip[1]) & \
            (flow['srcip_3'] == ip[2]) & (flow['srcip_4'] == ip[3]) & \
            (flow['dstip_1'] == ip[4]) & (flow['dstip_2'] == ip[5]) & \
            (flow['dstip_3'] == ip[6]) & (flow['dstip_4'] == ip[7])]
          
        if len(group) > 1 and len(group) <= threshold:           
            result = calculateBwd(group, ip, x, slot_num, slot_size)
            slot_num = result[0]
            slot_size = result[1]

        elif len(group) > threshold:
            remain_flow = remain_flow.append(group)

    return [remain_flow, slot_num, slot_size]
	

def calculateBwd(df, ip, i, slot_num, slot_size):
    start = timeInterval_set[i][0].hour*3600 + timeInterval_set[i][0].minute*60
    end = timeInterval_set[i][1].hour*3600 + timeInterval_set[i][1].minute*60
    slot_count = (end-start) / 60
    
    loc_set = []
    for index, row in df.iterrows():
        flow_start_time = row['start_date_time'].hour*3600 + row['start_date_time'].minute*60+ row['start_date_time'].second
        flow_end_time = row['end_date_time'].hour*3600 + row['end_date_time'].minute*60+ row['end_date_time'].second

        sloc = (flow_start_time-start) / 60
        eloc = (flow_end_time-start) / 60

        if sloc < 0:
            sloc = 0
        if eloc > 21:
            eloc = 21

        slot_num[sloc:eloc+1] = slot_num[sloc:eloc+1] + 1
        loc_set.extend(range(sloc, eloc+1))

    #drawPict(len(df), small_interval, overlap_interval, ip, i)

    loc_set = list(set(loc_set))
    slot_size[loc_set] = slot_size[loc_set] + 1

    return [slot_num, slot_size]
	

def drawPict(flow_size, small_interval, overlap_interval, ip, i):
    plt.title('IP Prefix: ' + str(ip) + \
    '\nTime Range: ' + timeInterval_set[i][0].strftime("%H:%M") + ' ~ ' + timeInterval_set[i][1].strftime("%H:%M") + \
    ', Total: ' + str(flow_size) + ' flows\n')

    plt.xlabel('Time')
    plt.ylabel('Bandwidth (Kbyte/s)')

    x = list(range(len(small_interval)))
    plt.xticks(x, [])

    loc = map(lambda a:a+0.5, x)
    width = 0.5

    bar = plt.bar(loc, small_interval, width, align='center')

    plt.ylim(ymin=0, ymax=max(small_interval))
    plt.xlim(xmin=0, xmax=len(x))
    
    for index, rect in enumerate(bar):
        if overlap_interval[index] > 0:
            height = rect.get_height()
            plt.text(rect.get_x() + rect.get_width()/2.0, height, str(overlap_interval[index]), ha='center', va='bottom')
    
    plt.tight_layout()
    plt.savefig('png/' + str(i+1) + '_' + str(ip) + '.png')
    plt.gcf().clear()


pd.set_option('expand_frame_repr', False)

elephantFlow['srcip_1'], elephantFlow['srcip_2'], elephantFlow['srcip_3'], elephantFlow['srcip_4'] = \
zip(*elephantFlow['srcip'].map(lambda x: x.split('.')))
elephantFlow['dstip_1'], elephantFlow['dstip_2'], elephantFlow['dstip_3'], elephantFlow['dstip_4'] = \
zip(*elephantFlow['dstip'].map(lambda x: x.split('.')))

cols = ['start_date_time', 'end_date_time', 'srcip', 'srcip_1', 'srcip_2', 'srcip_3', 'srcip_4', \
'dstip', 'dstip_1', 'dstip_2', 'dstip_3', 'dstip_4', 'srcport', 'dstport', 'protocol']
elephantFlow = elephantFlow[cols]

elephantFlow['start_date_time'] = pd.to_datetime(elephantFlow['start_date_time'])
elephantFlow['end_date_time'] = pd.to_datetime(elephantFlow['end_date_time'])

flow_start_time = elephantFlow['start_date_time'].dt.hour*3600 + elephantFlow['start_date_time'].dt.minute*60
flow_end_time = elephantFlow['end_date_time'].dt.hour*3600 + elephantFlow['end_date_time'].dt.minute*60

time_group = [0, 0, 0]
slot_num = [[], [], []]
slot_size = [[], [], []]
for x, interval in enumerate(timeInterval_set):
    result = groupTime(interval, elephantFlow, flow_start_time, flow_end_time)
    time_group[x] = result[0]
    slot_num[x] = np.zeros((result[1],), dtype=np.int)
    slot_size[x] = np.zeros((result[1],), dtype=np.int)

for x, group in enumerate(time_group):
    result = groupPrefix(1, ['srcip_1', 'dstip_1'], group, x, slot_num[x], slot_size[x])
    remain_flow = result[0]
    slot_num[x] = result[1]
    slot_size[x] = result[2]

    result = groupPrefix(2, ['srcip_1', 'srcip_2', 'dstip_1', 'dstip_2'], remain_flow, x, slot_num[x], slot_size[x])
    remain_flow = result[0]
    slot_num[x] = result[1]
    slot_size[x] = result[2]

    result = groupPrefix(3, ['srcip_1', 'srcip_2', 'srcip_3', 'dstip_1', 'dstip_2', 'dstip_3'], \
    remain_flow, x, slot_num[x], slot_size[x])
    remain_flow = result[0]
    slot_num[x] = result[1]
    slot_size[x] = result[2]

    result = groupPrefix(4, ['srcip_1', 'srcip_2', 'srcip_3', 'srcip_4', 'dstip_1', 'dstip_2', 'dstip_3', 'dstip_4'], \
    remain_flow, x, slot_num[x], slot_size[x])
    remain_flow = result[0]
    slot_num[x] = result[1]
    slot_size[x] = result[2]
   
for i in range(len(slot_num)):
    slot_num[i] = slot_num[i].astype(np.float32, copy=False)
    slot_size[i] = slot_size[i].astype(np.float32, copy=False)

    ans = np.around(slot_num[i] / slot_size[i])
    ans = list(ans.astype(np.int32, copy=False))

    plt.title('Time Range: ' + timeInterval_set[i][0].strftime("%H:%M") + ' ~ ' + timeInterval_set[i][1].strftime("%H:%M") + \
    '\n')

    plt.xlabel('Time')
    plt.ylabel('Average Flow Numbers')

    x = list(range(len(ans)))
    plt.xticks(x, [])

    loc = map(lambda a:a+0.5, x)
    width = 0.5

    bar = plt.bar(loc, ans, width, align='center')

    plt.ylim(ymin=0, ymax=10)
    plt.xlim(xmin=0, xmax=len(x))
    
    for index, rect in enumerate(bar):
        if ans[index] > 0:
            height = rect.get_height()
            plt.text(rect.get_x() + rect.get_width()/2.0, height, str(ans[index]), ha='center', va='bottom')
    
    plt.tight_layout()
    plt.savefig(str(i+1) + '.png')
    plt.gcf().clear()


print 'program start at ' + str(time.strftime('%Y-%m-%d %H:%M:%S'))
