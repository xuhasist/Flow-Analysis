import os
import time
import datetime
import numpy as np
import pandas as pd
from subprocess import Popen, PIPE, STDOUT

os.system('javac Tree.java')
elephantFlowIndex = Popen(['java', 'Tree'], stdout=PIPE, stderr=STDOUT).stdout.read().split(',')

df = pd.read_csv('univ1/csv/univ1_all.csv')
elephantFlow = df.iloc[elephantFlowIndex]
elephantFlow = elephantFlow.reset_index(drop=True)

ip_df = pd.DataFrame([], columns=['ip'])

src_ip = elephantFlow['srcip'].tolist()
dst_ip = elephantFlow['dstip'].tolist()

ip_df['ip'] = src_ip + dst_ip
ip_df = ip_df.drop_duplicates()

ip_df['ip_1'], ip_df['ip_2'], ip_df['ip_3'], ip_df['ip_4'] = \
zip(*ip_df['ip'].map(lambda x: x.split('.')))

ip_df['ip_1'] = ip_df['ip_1'].astype(int)
ip_df['ip_2'] = ip_df['ip_2'].astype(int)
ip_df['ip_3'] = ip_df['ip_3'].astype(int)
ip_df['ip_4'] = ip_df['ip_4'].astype(int)

ip_df = ip_df.sort_values(['ip_1', 'ip_2', 'ip_3', 'ip_4'])
ip_df = ip_df.reset_index(drop=True)
print ip_df['ip'].tolist()

tier_1 = []
tier_2 = []
tier_3 = []
tier_4 = []

temp = []
aa = 0

ip1 = ip_df['ip_1'].drop_duplicates()
split_num = len(ip1) / 8
start = 0
count_1 = 0
while start < len(ip1):
    for ip_1 in ip1[start:start+split_num]:
        count_1 = count_1 + 1
        tier_1.append(count_1)
        ip1_filter = ip_df[(ip_df['ip_1'] == ip_1)]

        ip2 = ip1_filter['ip_2'].drop_duplicates()
        #temp.append(len(ip2))
        #aa = aa + len(ip2)
        count_2 = 0
        for ip_2 in ip2:
            count_2 = count_2 + 1
            str_2 = str(count_1) + '-' + str(count_2)
            tier_2.append(str_2)
            ip2_filter = ip1_filter[(ip1_filter['ip_2'] == ip_2)]

            ip3 = ip2_filter['ip_3'].drop_duplicates()
            #temp.append(len(ip3))
            #aa = aa + len(ip3)
            count_3 = 0
            for ip_3 in ip3:
                count_3 = count_3 + 1
                str_3 = str_2 + '-' + str(count_3)
                tier_3.append(str_3)
                ip3_filter = ip2_filter[(ip2_filter['ip_3'] == ip_3)]

                ip4 = ip3_filter['ip_4'].drop_duplicates()
                #temp.append(len(ip4))
                #aa = aa + len(ip4)
                count_4 = 0
                for ip_4 in ip4:
                    count_4 = count_4 + 1
                    tier_4.append(str_3 + '-' + str(count_4))
                    ip4_filter = ip3_filter[(ip3_filter['ip_4'] == ip_4)]
                    #print ip4_filter
                    #print
                
    start = start + split_num

#print temp
#print len(temp)
#print aa
'''
print 'tier 1: %d' %(len(tier_1))
print 'tier 2: %d' %(len(tier_2))
print 'tier 3: %d' %(len(tier_3))
print 'tier 4: %d' %(len(tier_4))
print
print 'total: %d' %(len(tier_1) + len(tier_2) + len(tier_3) + len(tier_4))
print
print tier_1
print
print tier_2
print
print tier_3
print
print tier_4
'''






