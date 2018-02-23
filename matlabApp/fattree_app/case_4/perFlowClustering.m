function [meanFlowTableSize_perFlow, meanNetworkThrouput_perFlow] =  ...
    perFlowClustering(flowStartDatetime, flowEndDatetime, linkBwdUnit, ...
    hostIpTable, flowTraceTable, swFlowEntryStruct, g, swInfTable, linkTable, linkThputStruct)
        
    eachFlowFinalPath = {};
    linkPreLower = [];
        
    for i = 1:size(flowTraceTable, 1)
        ['per-flow ', int2str(i)]
        
        [srcNodeName, dstNodeName, flowStartStrtime, flowEndStrtime, flowRate, flowTraceTable, flowEntry] = ...
            setFlowInfo(flowStartDatetime(i), flowEndDatetime(i), linkBwdUnit, hostIpTable, flowTraceTable, i);
        
        rows = strcmp(swInfTable.SrcNode, srcNodeName);
        srcEdgeSw = swInfTable{rows, {'DstNode'}}{1};

        rows = strcmp(swInfTable.SrcNode, dstNodeName);
        dstEdgeSw = swInfTable{rows, {'DstNode'}}{1};

        finalPath = findnode(g, srcNodeName);
        
        prefixLength = 32;
        [flowEntry, flowSrcIp, flowDstIp]  = setFlowEntry(prefixLength, flowEntry, flowTraceTable, i);

        rows = strcmp(swInfTable.SrcNode, srcNodeName);
        flowEntry.input = swInfTable{rows, {'DstInf'}};

        round = 3;

        [finalPath, swFlowEntryStruct, linkTable, finish] = ...
            processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
            swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry, finalPath, ...
            flowStartDatetime(i), srcEdgeSw, dstEdgeSw, round, dstNodeName, flowSrcIp, flowDstIp);
        
        finalPath = [finalPath, findnode(g, dstNodeName)];
        finalPath(diff(finalPath)==0) = [];
        eachFlowFinalPath = [eachFlowFinalPath; finalPath];

        [linkThputStruct, linkPreLower] = ...
            updateLinkStruct(finalPath, g, linkThputStruct, ...
            flowStartDatetime(i), flowEndDatetime(i), flowEndStrtime, linkPreLower, flowEntry, flowRate);
    end
    
    [meanFlowTableSize_1, meanFlowTableSize_2, meanFlowTableSize_3, meanFlowTableSize_4, meanFlowTableSize_5, meanFlowTableSize_6, meanFlowTableSize_7, meanFlowTableSize_8] = ...
        calculateFlowTableSize(swFlowEntryStruct);
    
    meanFlowTableSize_perFlow = meanFlowTableSize_1;
    
    [linkThputStruct, meanNetworkThrouput] = ...
        calculateNetworkThrouput(g, linkBwdUnit, ...
        linkThputStruct, eachFlowFinalPath, flowTraceTable, flowStartDatetime, flowEndDatetime);
    
    meanNetworkThrouput_perFlow = meanNetworkThrouput;
end