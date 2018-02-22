clearvars -except

t1 = datetime('now');

hostAvg = 50;
hostSd = 5;
    
flowNum = 5000;

linkBwdUnit = 10^3; %10Kbps
startPrefixLength = 9;
endPrefixLength = 20;

x_axis = startPrefixLength:endPrefixLength;

allRound_y_axis_flowTableSize_1 = [];
allRound_y_axis_flowTableSize_2 = [];
allRound_y_axis_flowTableSize_3 = [];
allRound_y_axis_flowTableSize_4 = [];
allRound_y_axis_flowTableSize_5 = [];
allRound_y_axis_flowTableSize_6 = [];
allRound_y_axis_flowTableSize_7 = [];
allRound_y_axis_flowTableSize_8 = [];

allRound_y_axis_networkThroughput = [];

roundNumber = 10;
for frequency = 1:roundNumber
    % fat tree
    k = 4;
    [swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP] = ...
        createFatTreeTopo(k, hostAvg, hostSd);

    % AS topo
    %eachAsEdgeSwNum = 2;
    %[swNum, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeTable, hostNum, IP] = ...
        %createAsTopo_random(eachAsEdgeSwNum, hostAvg, hostSd);

    
    [swInfTable, swFlowEntryStruct, hostIpTable, linkTable, linkThputStruct, flowTraceTable, flowSequence] = ...
        setVariables(swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP, flowNum);


    % remove mice flow
    flowStartDatetime = datetime(flowTraceTable.StartDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    flowEndDatetime = datetime(flowTraceTable.EndDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

    rows = (flowEndDatetime - flowStartDatetime < seconds(1));
    flowTraceTable(rows, :) = [];
    
    flowStartDatetime(rows) = [];
    flowEndDatetime(rows) = [];
    
    
    swDistanceVector = distances(g, 'Method', 'unweighted');
    swDistanceVector = swDistanceVector(1:swNum, 1:swNum);
    
    % for as topo
    %rows = strcmp(nodeTable.Type, 'RT_NODE');
    %swDistanceVector(rows, rows) = 0;
    
    
    [idx, group_num] = doKmeans(flowSequence);
    
    swFlowEntryStruct_empty = swFlowEntryStruct;
    linkTable_empty = linkTable;
    linkThputStruct_empty = linkThputStruct;

    y_axis_flowTableSize_1 = [];
    y_axis_flowTableSize_2 = [];
    y_axis_flowTableSize_3 = [];
    y_axis_flowTableSize_4 = [];
    y_axis_flowTableSize_5 = [];
    y_axis_flowTableSize_6 = [];
    y_axis_flowTableSize_7 = [];
    y_axis_flowTableSize_8 = [];
    
    y_axis_networkThroughput = [];

    for pl = startPrefixLength:endPrefixLength
        swFlowEntryStruct = swFlowEntryStruct_empty;
        linkTable = linkTable_empty;
        linkThputStruct = linkThputStruct_empty;
        
        eachFlowFinalPath = {};
        linkPreLower = [];
        needDohierarchy = false;  
        
        flowTraceTable.Group = repmat(-1, size(flowTraceTable, 1), 1);
        flowTraceTable.HierarchicalGroup = zeros(size(flowTraceTable, 1), 1);
        flowTraceTable.MiddleSrcSw = repmat({{}}, size(flowTraceTable, 1), 1);
        flowTraceTable.MiddleDstSw = repmat({{}}, size(flowTraceTable, 1), 1);
        flowTraceTable.ClusterPort = zeros(size(flowTraceTable, 1), 1);

        if pl < 16
            original_pl = pl;
            pl = 16;
            
            needDohierarchy = true;
        end
        
        if needDohierarchy
            flowTraceTable = hierarchicalClustering_fixedPrefix(original_pl, g, swDistanceVector, hostIpTable, swInfTable, flowTraceTable, idx, group_num);
        else
            flowTraceTable = simularityClustering_fixedPrefix(pl, flowTraceTable, idx, group_num);
        end

        for i = 1:size(flowTraceTable, 1)
            i
            
            [srcNodeName, dstNodeName, flowStartStrtime, flowEndStrtime, flowRate, flowTraceTable, flowEntry] = ...
                setFlowInfo(flowStartDatetime(i), flowEndDatetime(i), linkBwdUnit, hostIpTable, flowTraceTable, i);

            rows = strcmp(swInfTable.SrcNode, srcNodeName);
            srcEdgeSw = swInfTable{rows, {'DstNode'}}{1};

            rows = strcmp(swInfTable.SrcNode, dstNodeName);
            dstEdgeSw = swInfTable{rows, {'DstNode'}}{1};

            finalPath = findnode(g, srcNodeName);
            
            if needDohierarchy
                middleSrcSw = flowTraceTable.MiddleSrcSw{i};
                middleDstSw = flowTraceTable.MiddleDstSw{i};
                
                swList = {srcEdgeSw, middleSrcSw, middleDstSw, dstEdgeSw};
                prefixList = [pl, original_pl, pl];
                
                for j = 1:length(swList) - 1
                    firstSw = swList{j};
                    secondSw = swList{j+1};
                    
                    [flowEntry_temp, flowSrcIp, flowDstIp] = setFlowEntry(prefixList(j), flowEntry, flowTraceTable, i);
                    
                    if flowTraceTable.ClusterPort(i) ~= 0
                        flowEntry_temp.srcPort = flowTraceTable.ClusterPort(i);
                    end
                    
                    if strcmp(firstSw, srcEdgeSw)
                        rows = strcmp(swInfTable.SrcNode, srcNodeName);
                        flowEntry_temp.input = swInfTable{rows, {'DstInf'}};
                    else
                        rows = strcmp(swInfTable.SrcNode, g.Nodes.Name{finalPath(end-1)}) & strcmp(swInfTable.DstNode, g.Nodes.Name{finalPath(end)});
                        flowEntry_temp.input = swInfTable{rows, {'DstInf'}};
                    end
            
                    round = j;
                    finalPath_temp = [];
                                        
                    [finalPath_temp, swFlowEntryStruct, linkTable, finish] = ...
                        processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                        swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry_temp, finalPath_temp, ...
                        flowStartDatetime(i), firstSw, secondSw, round, dstNodeName, flowSrcIp, flowDstIp);
                
                    finalPath = [finalPath, finalPath_temp];
                    
                    if finish
                        break;
                    end
                end
            else
                [flowEntry, flowSrcIp, flowDstIp]  = setFlowEntry(pl, flowEntry, flowTraceTable, i);

                rows = strcmp(swInfTable.SrcNode, srcNodeName);
                flowEntry.input = swInfTable{rows, {'DstInf'}};

                round = 3;
                
                [finalPath, swFlowEntryStruct, linkTable, finish] = ...
                    processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                    swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry, finalPath, ...
                    flowStartDatetime(i), srcEdgeSw, dstEdgeSw, round, dstNodeName, flowSrcIp, flowDstIp);
            end
            
            finalPath = [finalPath, findnode(g, dstNodeName)];
            finalPath(diff(finalPath)==0) = [];
            eachFlowFinalPath = [eachFlowFinalPath; finalPath];

            [linkThputStruct, linkPreLower] = ...
                updateLinkStruct(finalPath, g, linkThputStruct, ...
                flowStartDatetime(i), flowEndDatetime(i), flowEndStrtime, linkPreLower, flowEntry, flowRate);
        end

        [meanFlowTableSize_1, meanFlowTableSize_2, meanFlowTableSize_3, meanFlowTableSize_4, meanFlowTableSize_5, meanFlowTableSize_6, meanFlowTableSize_7, meanFlowTableSize_8] = ...
            calculateFlowTableSize(swFlowEntryStruct);
        
        y_axis_flowTableSize_1 = [y_axis_flowTableSize_1, meanFlowTableSize_1];
        y_axis_flowTableSize_2 = [y_axis_flowTableSize_2, meanFlowTableSize_2];
        y_axis_flowTableSize_3 = [y_axis_flowTableSize_3, meanFlowTableSize_3];
        y_axis_flowTableSize_4 = [y_axis_flowTableSize_4, meanFlowTableSize_4];
        y_axis_flowTableSize_5 = [y_axis_flowTableSize_5, meanFlowTableSize_5];
        y_axis_flowTableSize_6 = [y_axis_flowTableSize_6, meanFlowTableSize_6];
        y_axis_flowTableSize_7 = [y_axis_flowTableSize_7, meanFlowTableSize_7];
        y_axis_flowTableSize_8 = [y_axis_flowTableSize_8, meanFlowTableSize_8];

        [linkThputStruct, meanNetworkThrouput] = ...
            calculateNetworkThrouput(g, linkBwdUnit, ...
            linkThputStruct, eachFlowFinalPath, flowTraceTable, flowStartDatetime, flowEndDatetime);
        
        y_axis_networkThroughput = [y_axis_networkThroughput, meanNetworkThrouput];
        
        if needDohierarchy
            flowTraceTable = hierarchicalClustering_fixedPrefix(original_pl, g, swDistanceVector, hostIpTable, swInfTable, flowTraceTable, idx, group_num);
            filename = ['memory/memory_', int2str(frequency), '_', int2str(original_pl)];
        else
            flowTraceTable = simularityClustering_fixedPrefix(pl, flowTraceTable, idx, group_num);
            filename = ['memory/memory_', int2str(frequency), '_', int2str(pl)];
        end
        
        save(filename)
    end
        
    allRound_y_axis_flowTableSize_1 = [allRound_y_axis_flowTableSize_1; y_axis_flowTableSize_1];
    allRound_y_axis_flowTableSize_2 = [allRound_y_axis_flowTableSize_2; y_axis_flowTableSize_2];
    allRound_y_axis_flowTableSize_3 = [allRound_y_axis_flowTableSize_3; y_axis_flowTableSize_3];
    allRound_y_axis_flowTableSize_4 = [allRound_y_axis_flowTableSize_4; y_axis_flowTableSize_4];
    allRound_y_axis_flowTableSize_5 = [allRound_y_axis_flowTableSize_5; y_axis_flowTableSize_5];
    allRound_y_axis_flowTableSize_6 = [allRound_y_axis_flowTableSize_6; y_axis_flowTableSize_6];
    allRound_y_axis_flowTableSize_7 = [allRound_y_axis_flowTableSize_7; y_axis_flowTableSize_7];
    allRound_y_axis_flowTableSize_8 = [allRound_y_axis_flowTableSize_8; y_axis_flowTableSize_8];
    
    allRound_y_axis_networkThroughput = [allRound_y_axis_networkThroughput; y_axis_networkThroughput];
    
    if frequency == 1
        drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_1, 1, frequency)
        drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_2, 2, frequency)
        drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_3, 3, frequency)
        drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_4, 4, frequency)
        drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_5, 5, frequency)
        drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_6, 6, frequency)
        drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_7, 7, frequency)
        drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_8, 8, frequency)
        
        drawNetworkThroughputFigure(x_axis, allRound_y_axis_networkThroughput, frequency)
    else
        drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_1), 1, frequency)
        drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_2), 2, frequency)
        drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_3), 3, frequency)
        drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_4), 4, frequency)
        drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_5), 5, frequency)
        drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_6), 6, frequency)
        drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_7), 7, frequency)
        drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_8), 8, frequency)
        
        drawNetworkThroughputFigure(x_axis, mean(allRound_y_axis_networkThroughput), frequency)
    end
end

t2 = datetime('now');
disp(t2 - t1)

function [idx, k] = doKmeans(flowSequence)
    k = 0;
    pre_avgDistance = -1;
    avgDistance = -1;
    
    while pre_avgDistance == -1 || ~(avgDistance >= pre_avgDistance * (95/100) && avgDistance <= pre_avgDistance)
        k = k + 1;
        pre_avgDistance = avgDistance;
        
        [idx, C, sumd] = kmeans(flowSequence, k);
        
        avg_sumd = [];
        for i = 1:length(sumd)
            avg_sumd(i) = (sumd(i) / length(find(idx == i)));
        end
        avgDistance = mean(avg_sumd);
    end
end