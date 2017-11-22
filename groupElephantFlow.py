import os
import time
import datetime
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from subprocess import Popen, PIPE, STDOUT

print 'program start at ' + str(time.strftime('%Y-%m-%d %H:%M:%S'))

timeInterval_set = [(datetime.datetime.strptime('00:25', "%H:%M"), datetime.datetime.strptime('00:47', "%H:%M")), \
(datetime.datetime.strptime('00:47', "%H:%M"), datetime.datetime.strptime('01:09', "%H:%M")), \
(datetime.datetime.strptime('01:09', "%H:%M"), datetime.datetime.strptime('01:32', "%H:%M"))]   

threshold = 465

df_allPkt = pd.read_csv('univ1/univ1_filter.csv')

df_allPkt['DateTime'] = pd.to_datetime(df_allPkt['DateTime'])
df_allPkt['Protocol'] = np.where(df_allPkt['Protocol']==6, 'TCP', 'UDP')

allPkt_time = df_allPkt['DateTime'].dt.hour*3600 + df_allPkt['DateTime'].dt.minute*60 + df_allPkt['DateTime'].dt.second


def main():
    pd.set_option('expand_frame_repr', False)

    os.system('javac Tree.java')
    elephantFlowIndex = Popen(['java', 'Tree'], stdout=PIPE, stderr=STDOUT).stdout.read().split(',')

    df = pd.read_csv('univ1/csv/univ1_all.csv')
    elephantFlow = df.iloc[elephantFlowIndex]
    elephantFlow = elephantFlow.reset_index(drop=True)

    del elephantFlowIndex
    del df

    elephantFlow['srcip_1'], elephantFlow['srcip_2'], elephantFlow['srcip_3'], elephantFlow['srcip_4'] = \
    zip(*elephantFlow['srcip'].map(lambda x: x.split('.')))
    elephantFlow['dstip_1'], elephantFlow['dstip_2'], elephantFlow['dstip_3'], elephantFlow['dstip_4'] = \
    zip(*elephantFlow['dstip'].map(lambda x: x.split('.')))

    cols = ['start_date_time', 'end_date_time', 'srcip', 'srcip_1', 'srcip_2', 'srcip_3', 'srcip_4', \
    'dstip', 'dstip_1', 'dstip_2', 'dstip_3', 'dstip_4', 'srcport', 'dstport', 'protocol']
    elephantFlow = elephantFlow[cols]

    elephantFlow['start_date_time'] = pd.to_datetime(elephantFlow['start_date_time'])
    elephantFlow['end_date_time'] = pd.to_datetime(elephantFlow['end_date_time'])

    #print '\n%d elephant flows' %(len(elephantFlow))
    #print '\nthreshold = %d\n' %(threshold)

    remain_flow = groupPrefix(1, ['srcip_1', 'dstip_1'], elephantFlow)
    remain_flow = groupPrefix(2, ['srcip_1', 'srcip_2', 'dstip_1', 'dstip_2'], remain_flow)
    remain_flow = groupPrefix(3, ['srcip_1', 'srcip_2', 'srcip_3', 'dstip_1', 'dstip_2', 'dstip_3'], remain_flow)
    remain_flow = groupPrefix(4, ['srcip_1', 'srcip_2', 'srcip_3', 'srcip_4', 'dstip_1', 'dstip_2', 'dstip_3', 'dstip_4'], \
    remain_flow)

    #print len(remain_flow)
    

def groupPrefix(n, prefix_list, elephantFlow):
    subset = elephantFlow[prefix_list]
    ip_set = set(tuple(x) for x in subset.values)
    del subset
    
    remain_flow = pd.DataFrame([], columns=['start_date_time', 'end_date_time', 'srcip', 'srcip_1', 'srcip_2', \
    'srcip_3', 'srcip_4', 'dstip', 'dstip_1', 'dstip_2', 'dstip_3', 'dstip_4', 'srcport', 'dstport', 'protocol'])

    #group_size = []
    #time1_size = []
    #time2_size = []
    #time3_size = []
    for ip in ip_set:
        if n == 1:
            group = elephantFlow[(elephantFlow['srcip_1'] == ip[0]) & (elephantFlow['dstip_1'] == ip[1])]
        elif n == 2:
            group = elephantFlow[(elephantFlow['srcip_1'] == ip[0]) & (elephantFlow['srcip_2'] == ip[1]) & \
            (elephantFlow['dstip_1'] == ip[2]) & (elephantFlow['dstip_2'] == ip[3])]
        elif n == 3:
            group = elephantFlow[(elephantFlow['srcip_1'] == ip[0]) & (elephantFlow['srcip_2'] == ip[1]) & \
            (elephantFlow['srcip_3'] == ip[2]) & (elephantFlow['dstip_1'] == ip[3]) & \
            (elephantFlow['dstip_2'] == ip[4]) & (elephantFlow['dstip_3'] == ip[5])]
        elif n == 4:
            group = elephantFlow[(elephantFlow['srcip_1'] == ip[0]) & (elephantFlow['srcip_2'] == ip[1]) & \
            (elephantFlow['srcip_3'] == ip[2]) & (elephantFlow['srcip_4'] == ip[3]) & \
            (elephantFlow['dstip_1'] == ip[4]) & (elephantFlow['dstip_2'] == ip[5]) & \
            (elephantFlow['dstip_3'] == ip[6]) & (elephantFlow['dstip_4'] == ip[7])]
           
        if len(group) > 1 and len(group) <= threshold:
            size = [0, 0, 0]
            result = [0, 0, 0]
            for x, interval in enumerate(timeInterval_set):
                result[x] = groupTime(interval, group)
                size[x] = size[x] + len(result[x])

            if max(size) > 1:
                '''
                group_size.append(len(group))
                time1_size.append(size[0])
                time2_size.append(size[1])
                time3_size.append(size[2])
                '''
                #print '\nprefix src/dst ip = %s' %(str(ip))
                #print 'group size = %d' %(len(group))

                for i, df in enumerate(result):
                '''
                    print '\n%s:%s ~ %s:%s : %d flows' %(str(timeInterval_set[i][0].hour), str(timeInterval_set[i][0].minute), \
                    str(timeInterval_set[i][1].hour), str(timeInterval_set[i][1].minute), len(df))
                    print df[['start_date_time', 'end_date_time', 'srcip', 'dstip', 'srcport', 'dstport', 'protocol']]        
				'''
                    if len(df) > 0:
                        calculateBwd(df, ip, i)

            del result
        elif len(group) > threshold:
            remain_flow = remain_flow.append(group)
    '''
    print '\n%d-bits: %d groups, min group size = %d, max group size = %d, average group size = %d' \
    %(n*8, len(group_size), min(group_size), max(group_size), np.mean(group_size))   

    print '\t%s:%s ~ %s:%s : %d groups, min group size = %d, max group size = %d, average group size = %d' \
    %(str(timeInterval_set[0][0].hour), str(timeInterval_set[0][0].minute), \
    str(timeInterval_set[0][1].hour), str(timeInterval_set[0][1].minute), len(time1_size), min(time1_size), max(time1_size), np.mean(time1_size)) 

    print '\t%s:%s ~ %s:%s : %d groups, min group size = %d, max group size = %d, average group size = %d' \
    %(str(timeInterval_set[1][0].hour), str(timeInterval_set[1][0].minute), \
    str(timeInterval_set[1][1].hour), str(timeInterval_set[1][1].minute),len(time2_size),  min(time2_size), max(time2_size), np.mean(time2_size)) 

    print '\t%s:%s ~ %s:%s : %d groups, min group size = %d, max group size = %d, average group size = %d' \
    %(str(timeInterval_set[2][0].hour), str(timeInterval_set[2][0].minute), \
    str(timeInterval_set[2][1].hour), str(timeInterval_set[2][1].minute),len(time3_size),  min(time3_size), max(time3_size), np.mean(time3_size)) 
    '''
    return remain_flow


def groupTime(interval, elephantFlow):
    start = interval[0].hour*3600 + interval[0].minute*60
    end = interval[1].hour*3600 + interval[1].minute*60

    flow_start_time = elephantFlow['start_date_time'].dt.hour*3600 + elephantFlow['start_date_time'].dt.minute*60
    flow_end_time = elephantFlow['end_date_time'].dt.hour*3600 + elephantFlow['end_date_time'].dt.minute*60

    group = elephantFlow[((flow_start_time >= start) & (flow_start_time < end)) | \
    ((flow_end_time >= start) & (flow_end_time < end))]

    del flow_start_time
    del flow_end_time

    return group
	

def calculateBwd(df, ip, i):
    start = timeInterval_set[i][0].hour*3600 + timeInterval_set[i][0].minute*60
    end = timeInterval_set[i][1].hour*3600 + timeInterval_set[i][1].minute*60
    slot_count = (end-start) / 30

    small_interval = [0] * slot_count
    overlap_interval = [0] * slot_count
    
    for index, row in df.iterrows():
        
        flow_start_time = row['start_date_time'].hour*3600 + row['start_date_time'].minute*60+ row['start_date_time'].second
        flow_end_time = row['end_date_time'].hour*3600 + row['end_date_time'].minute*60+ row['end_date_time'].second

        sloc = (flow_start_time-start) / 30
        eloc = (flow_end_time-start) / 30
        overlap_interval[sloc:eloc+1] = [x+1 for x in overlap_interval[sloc:eloc+1]]
        
        df_filter = df_allPkt[(df_allPkt['Protocol'] == row['protocol']) & \
        (df_allPkt['Src_IP'] == row['srcip']) & (df_allPkt['Dst_IP'] == row['dstip']) & \
        (df_allPkt['Src_Port'] == row['srcport']) & (df_allPkt['Dst_Port'] == row['dstport']) & \
        ((allPkt_time >= start) & (allPkt_time < end))]
        '''
        print row
        print df_filter[['DateTime', 'Src_IP', 'Dst_IP', 'Src_Port', 'Dst_Port', 'Protocol', 'Length(Bytes)']]
        print
        '''
        for j, flow in df_filter.iterrows():
            loc = (allPkt_time[j]-start) / 30              
            small_interval[loc] = small_interval[loc] + flow['Length(Bytes)']

        del df_filter
	
    #print
    #print str(ip)
    #print small_interval
    small_interval = [float("{0:.2f}".format((x/30.0)/1000.0)) for x in small_interval]
    #print small_interval
    drawPict(len(df), small_interval, overlap_interval, ip, i)
	

def drawPict(flow_size, small_interval, overlap_interval, ip, i):
    plt.title('IP Prefix: ' + str(ip) + \
    '\nTime Range: ' + timeInterval_set[i][0].strftime("%H:%M") + ' ~ ' + timeInterval_set[i][1].strftime("%H:%M") + ', Total: ' + str(flow_size) + ' flows\n')

    plt.xlabel('Time')
    plt.ylabel('Bandwidth (Kbyte/s)')

    x = list(range(len(small_interval)))
    plt.xticks(x, [])

    loc = map(lambda a:a+0.5, x)
    width = 0.5

    bar = plt.bar(loc, small_interval, width, align='center')
    #plt.plot(loc, small_interval)

    plt.ylim(ymin=0, ymax=max(small_interval))
    plt.xlim(xmin=0, xmax=len(x))
    
    for index, rect in enumerate(bar):
        if overlap_interval[index] > 0:
            height = rect.get_height()
            plt.text(rect.get_x() + rect.get_width()/2.0, height, str(overlap_interval[index]), ha='center', va='bottom')
    
    plt.tight_layout()
    #plt.show()
    plt.savefig('png2/' + str(ip) + '_' + str(i+1) + '.png')
    #print 'write ' + str(ip) + '_' + str(i+1) + '.png'

    plt.gcf().clear()


if __name__ == '__main__':
    main()
    print '\nprogram end at ' + str(time.strftime('%Y-%m-%d %H:%M:%S'))

