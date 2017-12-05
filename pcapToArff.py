import os
import sys
import time
import arff
import logging
import numpy as np
import pandas as pd
from io import StringIO
from itertools import chain
from multiprocessing import Pool
from collections import OrderedDict

logging.basicConfig(level=logging.DEBUG,  
                    format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',  
                    datefmt='%a, %d %b %Y %H:%M:%S',  
                    filename='/tmp/test.log',  
                    filemode='w')  

def main():
    pd.set_option('expand_frame_repr', False)

    outFileName = sys.argv[1]
    inFileName = sys.argv[2]

    inPkt = loadPcap(inFileName)
    del inFileName
        
    inPkt = unicode(inPkt, 'utf-8')
    inPkt = StringIO(inPkt)
    df = pd.read_csv(inPkt, names=['DateTime', 'Timestamp', 'Src_IP', 'Dst_IP', 'Src_Port', 'Dst_Port', \
    'Protocol', 'Length(Bytes)', 'TCP_Flags'])

    del inPkt

    df['DateTime'] = df['DateTime'].astype(str)
    df['Timestamp'] = df['Timestamp'].astype(float)
    df['Src_IP'] = df['Src_IP'].astype(str)
    df['Dst_IP'] = df['Dst_IP'].astype(str)
    df['Src_Port'] = df['Src_Port'].astype(int)
    df['Dst_Port'] = df['Dst_Port'].astype(int)
    df['Protocol'] = df['Protocol'].astype(int)
    df['Length(Bytes)'] = df['Length(Bytes)'].astype(int)
    #df['TCP_Flags'] = df['TCP_Flags'].astype(int)

    df[['DateTime', 'Src_IP', 'Dst_IP', 'Src_Port', 'Dst_Port', 'Protocol', \
    'Length(Bytes)']].to_csv('univ1_allPkt.csv', index=False)

    df = df.sort_values(['Protocol', 'Src_IP', 'Dst_IP', 'Src_Port', 'Dst_Port', 'Timestamp'])
    df = df.reset_index(drop=True)

    print 'packet counts = ' + str(len(df))

    df_copy = df.copy()
    df_copy.drop(['DateTime', 'Timestamp', 'Length(Bytes)', 'TCP_Flags'], axis=1, inplace=True)
    df_copy = df_copy.drop_duplicates()

    sliceIndex = df_copy.index.values.tolist()
    del sliceIndex[0]
    del df_copy
    
    df_flowSlice = np.array_split(df, sliceIndex)
    del df
    del sliceIndex

    pool = Pool(4)
    print 'generate dataframe'
    attributeFlows = pool.map(generateAttrFlows, df_flowSlice)
    pool.close()
    
    attributeFlows = filter(None, attributeFlows)
    attributeFlows = list(chain.from_iterable(attributeFlows))

    allFlow = pd.DataFrame(attributeFlows, columns=['start_date_time', 'end_date_time', 'srcip', 'dstip', 'protocol', 'srcport', 'dstport', 'num_packet', 'transferred_bytes', 'byte_thr_class', 'byte_thr_1000', 'byte_thr_5000', 'duration', 'duration_class', 'avg_byte_thr', 'max_pkt_size', 'min_pkt_size', 'avg_pkt_size', '1_pkt_size', '2_pkt_size', '3_pkt_size', '1+2_pkt_size', '1+2+3_pkt_size', '1+3_pkt_size', '2+3_pkt_size', '4_pkt_size', '5_pkt_size', '6_pkt_size', '7_pkt_size', '8_pkt_size', '9_pkt_size', '10_pkt_size', 'max_pkt_inter_time', 'min_pkt_inter_time', 'avg_pkt_inter_time', '12_pkt_inter_time', '23_pkt_inter_time', '34_pkt_inter_time', '45_pkt_inter_time', '56_pkt_inter_time', '67_pkt_inter_time', '78_pkt_inter_time', '89_pkt_inter_time', '910_pkt_inter_time', 'duration_1', 'duration_2', 'duration_3', 'duration_4', 'duration_5', 'duration_10', 'elephant'])

    del attributeFlows

    print 'create csv file'
    cols_to_keep = ['start_date_time', 'end_date_time', 'srcip', 'srcport', 'dstip', 'dstport', 'protocol', 'transferred_bytes']
    allFlow[cols_to_keep].to_csv(outFileName+'.csv', index=False)

    print 'create arff file'
    cols_to_keep = ['protocol', 'srcport', 'dstport', 'num_packet', 'transferred_bytes', 'byte_thr_class', 'byte_thr_1000', 'byte_thr_5000', 'duration', 'duration_class', 'avg_byte_thr', 'max_pkt_size', 'min_pkt_size', 'avg_pkt_size', '1_pkt_size', '2_pkt_size', '3_pkt_size', '1+2_pkt_size', '1+2+3_pkt_size', '1+3_pkt_size', '2+3_pkt_size', '4_pkt_size', '5_pkt_size', '6_pkt_size', '7_pkt_size', '8_pkt_size', '9_pkt_size', '10_pkt_size', 'max_pkt_inter_time', 'min_pkt_inter_time', 'avg_pkt_inter_time', '12_pkt_inter_time', '23_pkt_inter_time', '34_pkt_inter_time', '45_pkt_inter_time', '56_pkt_inter_time', '67_pkt_inter_time', '78_pkt_inter_time', '89_pkt_inter_time', '910_pkt_inter_time', 'duration_1', 'duration_2', 'duration_3', 'duration_4', 'duration_5', 'duration_10', 'elephant']

    createArffFile(outFileName, allFlow[cols_to_keep].values.tolist())


def loadPcap(inFileName):
    print 'load ' + inFileName

    return os.popen('tshark -r ' + inFileName + ' -Y "(tcp || udp) && !(icmp) && !(ipv6)" -T fields -e _ws.col.DateTime -e _ws.col.Time -e ip.src -e ip.dst -e tcp.srcport -e udp.srcport -e tcp.dstport -e udp.dstport -e ip.proto -e frame.len -e tcp.flags -E separator=, | tr -s ","').read()


def generateAttrFlows(flowSlice):
    logging.info(flowSlice.index[0])

    flowSlice['Timestamp_Shift'] = flowSlice['Timestamp'].shift(-1)
        
    index_temp = flowSlice.index[(flowSlice['Timestamp_Shift'] - flowSlice['Timestamp'] > 60)].tolist() 
    index_temp.append(flowSlice.index[-1])

    data = []
    startLoc = 0
    for i in range(len(index_temp)):
        endLoc = flowSlice.index.get_loc(index_temp[i])

        if endLoc == startLoc:
            continue

        if flowSlice.iloc[startLoc]['Protocol'] == 6:
            if ((flowSlice.iloc[startLoc]['TCP_Flags'] != 2 and flowSlice.iloc[startLoc]['TCP_Flags'] != 18) or \
            (flowSlice.iloc[endLoc]['TCP_Flags'] != 1 and flowSlice.iloc[endLoc]['TCP_Flags'] != 17 and \
            flowSlice.iloc[endLoc-1]['TCP_Flags'] != 1 and flowSlice.iloc[endLoc-1]['TCP_Flags'] != 17)):
                continue    
        
        packetSizes = flowSlice['Length(Bytes)'].tolist() 
        interTimes = (flowSlice['Timestamp'] - flowSlice['Timestamp'].shift(1)).tolist()
        del interTimes[0]

        attributeFlow = attrFlowTpl()
        for n, pktSize in enumerate(packetSizes[:10]):
            attributeFlow[str(n+1) + '_pkt_size'] = pktSize

        del packetSizes

        attributeFlow['1+2_pkt_size'] = attributeFlow['1_pkt_size'] + attributeFlow['2_pkt_size']
        attributeFlow['1+2+3_pkt_size'] = attributeFlow['1_pkt_size'] + attributeFlow['2_pkt_size'] + \
        attributeFlow['3_pkt_size']
        attributeFlow['1+3_pkt_size'] = attributeFlow['1_pkt_size'] + attributeFlow['3_pkt_size']
        attributeFlow['2+3_pkt_size'] = attributeFlow['2_pkt_size'] + attributeFlow['3_pkt_size']

        for n, interTime in enumerate(interTimes[:9]):
            attributeFlow[str(n+1) + str(n+2) + '_pkt_inter_time'] = interTime

        attributeFlow['portocol'] = 'TCP' if flowSlice.iloc[startLoc]['Protocol'] == 6 else 'UDP'
        attributeFlow['srcport'] = flowSlice.iloc[startLoc]['Src_Port']
        attributeFlow['dstport'] = flowSlice.iloc[startLoc]['Dst_Port']
        attributeFlow['num_packet'] = endLoc - startLoc + 1
        attributeFlow['transferred_bytes'] = np.sum(flowSlice.iloc[startLoc:endLoc+1]['Length(Bytes)'])

        attributeFlow['max_pkt_size'] = np.max(flowSlice.iloc[startLoc:endLoc+1]['Length(Bytes)'])
        attributeFlow['min_pkt_size'] = np.min(flowSlice.iloc[startLoc:endLoc+1]['Length(Bytes)'])
        attributeFlow['avg_pkt_size'] = np.mean(flowSlice.iloc[startLoc:endLoc+1]['Length(Bytes)'])

        attributeFlow['duration'] = flowSlice.iloc[endLoc]['Timestamp'] - flowSlice.iloc[startLoc]['Timestamp'] 

        if attributeFlow['duration'] == attributeFlow['duration_class'][0]:
            attributeFlow['duration_class'] = attributeFlow['duration_class'][0]
        elif attributeFlow['duration'] < attributeFlow['duration_class'][1]:
            attributeFlow['duration_class'] = attributeFlow['duration_class'][1]
        elif attributeFlow['duration'] < attributeFlow['duration_class'][2]:
            attributeFlow['duration_class'] = attributeFlow['duration_class'][2]
        elif attributeFlow['duration'] < attributeFlow['duration_class'][3]:
            attributeFlow['duration_class'] = attributeFlow['duration_class'][3]
        elif attributeFlow['duration'] < attributeFlow['duration_class'][4]:
            attributeFlow['duration_class'] = attributeFlow['duration_class'][4]
        elif attributeFlow['duration'] < attributeFlow['duration_class'][5]:
            attributeFlow['duration_class'] = attributeFlow['duration_class'][5]
        else:
            attributeFlow['duration_class'] = attributeFlow['duration_class'][6]

        attributeFlow['avg_byte_thr'] = (float)(attributeFlow['transferred_bytes'] / attributeFlow['duration'])

        attributeFlow['max_pkt_inter_time'] = np.max(interTimes)
        attributeFlow['min_pkt_inter_time'] = np.min(interTimes)
        attributeFlow['avg_pkt_inter_time'] = np.mean(interTimes)

        del interTimes

        if attributeFlow['avg_byte_thr'] == attributeFlow['byte_thr_class'][0]:
            attributeFlow['byte_thr_class'] = attributeFlow['byte_thr_class'][0]
        elif attributeFlow['avg_byte_thr'] < attributeFlow['byte_thr_class'][1]:
            attributeFlow['byte_thr_class'] = attributeFlow['byte_thr_class'][1]
        elif attributeFlow['avg_byte_thr'] < attributeFlow['byte_thr_class'][2]:
            attributeFlow['byte_thr_class'] = attributeFlow['byte_thr_class'][2]
        elif attributeFlow['avg_byte_thr'] < attributeFlow['byte_thr_class'][3]:
            attributeFlow['byte_thr_class'] = attributeFlow['byte_thr_class'][3]
        elif attributeFlow['avg_byte_thr'] < attributeFlow['byte_thr_class'][4]:
            attributeFlow['byte_thr_class'] = attributeFlow['byte_thr_class'][4]
        else:
            attributeFlow['byte_thr_class'] = attributeFlow['byte_thr_class'][5]

        if attributeFlow['avg_byte_thr'] < 1000:
            attributeFlow['byte_thr_1000'] = 'no'
        else:
            attributeFlow['byte_thr_1000'] = 'yes'

        if attributeFlow['avg_byte_thr'] < 5000:
            attributeFlow['byte_thr_5000'] = 'no'
        else:
            attributeFlow['byte_thr_5000'] = 'yes'

        if attributeFlow['duration'] < 1:
            attributeFlow['duration_1'] = 'no'
        else:
            attributeFlow['duration_1'] = 'yes'

        if attributeFlow['duration'] < 2:
            attributeFlow['duration_2'] = 'no'
        else:
            attributeFlow['duration_2'] = 'yes'

        if attributeFlow['duration'] < 3:
            attributeFlow['duration_3'] = 'no'
        else:
            attributeFlow['duration_3'] = 'yes'

        if attributeFlow['duration'] < 4:
            attributeFlow['duration_4'] = 'no'
        else:
            attributeFlow['duration_4'] = 'yes'

        if attributeFlow['duration'] < 5:
            attributeFlow['duration_5'] = 'no'
        else:
            attributeFlow['duration_5'] = 'yes'

        if attributeFlow['duration'] < 10:
            attributeFlow['duration_10'] = 'no'
        else:
            attributeFlow['duration_10'] = 'yes'

        if attributeFlow['duration'] > 1 and attributeFlow['avg_byte_thr'] > 1000:
            attributeFlow['elephant'] = 'yes'
        else:
            attributeFlow['elephant'] = 'no'

        attributeFlow['start_date_time'] = flowSlice.iloc[startLoc]['DateTime']
        attributeFlow['end_date_time'] = flowSlice.iloc[endLoc]['DateTime']
        attributeFlow['srcip'] = flowSlice.iloc[startLoc]['Src_IP']
        attributeFlow['dstip'] = flowSlice.iloc[startLoc]['Dst_IP']

        data.append(attributeFlow.values())
        del attributeFlow

        startLoc = endLoc + 1
    
    return data


def createArffFile(outFileName, attributeFlows):
    outFile = open(outFileName+'.arff', 'w')

    attribute = []
    attributeMap = attrFlowTpl()
    for key, value in attributeMap.iteritems():
        if key == 'start_date_time' or key == 'end_date_time' or key == 'srcip' or key == 'dstip':
            continue
        elif isinstance(value, list):
            attribute.append((key, map(str, value)))
        elif value == 0:
            attribute.append((key, 'NUMERIC'))   

    del attributeMap

    arffObj = {
        'description': u'',
        'relation': outFileName+'.arff',
        'attributes': attribute,
        'data': attributeFlows,
    }

    arff.dump(arffObj, outFile)
    outFile.close()
 

def attrFlowTpl():
    return OrderedDict([('start_date_time', ""), ('end_date_time', ""), ('srcip', ""), ('dstip', ""), \
    ('portocol', ['TCP', 'UDP']), ('srcport', 0), ('dstport', 0), ('num_packet', 0), \
    ('transferred_bytes', 0), ('byte_thr_class', [0, 1000, 5000, 20000, 50000, 999999999999999]), \
    ('byte_thr_1000', ['yes', 'no']), ('byte_thr_5000', ['yes', 'no']), ('duration', 0), \
    ('duration_class', [0, 1, 60, 180, 600, 1200, 1800]), ('avg_byte_thr', 0), ('max_pkt_size', 0), \
    ('min_pkt_size', 0), ('avg_pkt_size', 0), ('1_pkt_size', 0), ('2_pkt_size', 0), ('3_pkt_size', 0), \
    ('1+2_pkt_size', 0), ('1+2+3_pkt_size', 0), ('1+3_pkt_size', 0), ('2+3_pkt_size', 0), \
    ('4_pkt_size', 0), ('5_pkt_size', 0), ('6_pkt_size', 0), ('7_pkt_size', 0), \
    ('8_pkt_size', 0), ('9_pkt_size', 0), ('10_pkt_size', 0),  \
    ('max_pkt_inter_time', 0), ('min_pkt_inter_time', 0), ('avg_pkt_inter_time', 0), \
    ('12_pkt_inter_time', 0), ('23_pkt_inter_time', 0), ('34_pkt_inter_time', 0), ('45_pkt_inter_time', 0), \
    ('56_pkt_inter_time', 0), ('67_pkt_inter_time', 0), ('78_pkt_inter_time', 0), ('89_pkt_inter_time', 0), \
    ('910_pkt_inter_time', 0), ('duration_1', ['yes', 'no']), ('duration_2', ['yes', 'no']), ('duration_3', ['yes', 'no']), \
    ('duration_4', ['yes', 'no']), ('duration_5', ['yes', 'no']), ('duration_10', ['yes', 'no']), ('elephant', ['yes', 'no'])])


if __name__ == '__main__':
    print time.strftime('%Y-%m-%d %H:%M:%S')
    main()
    print time.strftime('%Y-%m-%d %H:%M:%S')
   

