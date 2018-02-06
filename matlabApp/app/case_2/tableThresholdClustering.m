clearvars -except

t1 = datetime('now');

global currentFlowTime

hostAvg = 50;
hostSd = 5;
    
flowNum = 5000;

linkBwdUnit = 10^3; %10Kbps
startTableThreshold = 50;
x_axis = startTableThreshold:25:500;

allRound_y_axis_flowTableSize = [];
allRound_y_axis_networkThroughput = [];

for frequency = 1:20
    % fat tree
    k = 4;
    [swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP] = ...
        createFatTreeTopo(k, hostAvg, hostSd);

    % AS topo
    %eachAsEdgeSwNum = 5;
    %[swNum, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeTable, hostNum, IP] = ...
    %    createAsTopo(eachAsEdgeSwNum, hostAvg, hostSd);

    
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
    

    swFlowEntryStruct_empty = swFlowEntryStruct;
    linkTable_empty = linkTable;
    linkThputStruct_empty = linkThputStruct;

    y_axis_flowTableSize = [];
    y_axis_networkThroughput = [];
    doHierarchyCount_list = [];
    
    for tableThreshold = startTableThreshold:25:500
        swFlowEntryStruct = swFlowEntryStruct_empty;
        linkTable = linkTable_empty;
        linkThputStruct = linkThputStruct_empty;
        
        eachFlowFinalPath = {};
        linkPreLower = [];
        needDohierarchy = false;
        doHierarchyCount = 0;
        
        flowTraceTable.Group = repmat(-1, size(flowTraceTable, 1), 1);
        flowTraceTable.Prefix = repmat(16, size(flowTraceTable, 1), 1);
        flowTraceTable.HierarchicalGroup = zeros(size(flowTraceTable, 1), 1);
        flowTraceTable.MiddleSrcSw = repmat({{}}, size(flowTraceTable, 1), 1);
        flowTraceTable.MiddleDstSw = repmat({{}}, size(flowTraceTable, 1), 1);
        flowTraceTable.HierarchicalPrefix = zeros(size(flowTraceTable, 1), 1);
        
        flowTraceTable = simularityClustering_tableThreshold(g, hostIpTable, swInfTable, flowTraceTable, flowSequence);
        
        preCheckTableTime = datetime(flowTraceTable{1, 'StartDatetime'}{1}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        for i = 1:size(flowTraceTable, 1)
            i
            
            [srcNodeName, dstNodeName, flowStartStrtime, flowEndStrtime, flowRate, flowTraceTable, flowEntry] = ...
                setFlowInfo(flowStartDatetime(i), flowEndDatetime(i), linkBwdUnit, hostIpTable, flowTraceTable, i);
            
            currentFlowTime = flowStartDatetime(i);
    
            if currentFlowTime - preCheckTableTime >= seconds(60)
                [needDohierarchy, swWithTooManyFlowEntry] = ...
                    checkFlowTable(tableThreshold, swFlowEntryStruct, needDohierarchy);
                
                preCheckTableTime = currentFlowTime;
            end
            
            if needDohierarchy
                doHierarchyCount = doHierarchyCount + 1;
                flowTraceTable = hierarchicalClustering_tableThreshold(tableThreshold, swWithTooManyFlowEntry, g, swDistanceVector, hostIpTable, swInfTable, eachFlowFinalPath, flowTraceTable);
                
                needDohierarchy = false;
                swFlowEntryStruct = removeAllFlowEntry(swFlowEntryStruct, flowStartDatetime(i));
            end
            
            rows = strcmp(swInfTable.SrcNode, srcNodeName);
            srcEdgeSw = swInfTable{rows, {'DstNode'}}{1};

            rows = strcmp(swInfTable.SrcNode, dstNodeName);
            dstEdgeSw = swInfTable{rows, {'DstNode'}}{1};

            finalPath = findnode(g, srcNodeName);
            
            if flowTraceTable.HierarchicalGroup(i) > 0
                middleSrcSw = flowTraceTable.MiddleSrcSw{i};
                middleDstSw = flowTraceTable.MiddleDstSw{i};
                
                swList = {srcEdgeSw, middleSrcSw, middleDstSw, dstEdgeSw};
                
                prefixLength = flowTraceTable.Prefix(i);
                hie_prefixLength = flowTraceTable.HierarchicalPrefix(i);
                
                prefixList = [prefixLength, hie_prefixLength, prefixLength];
                
                for j = 1:length(swList) - 1
                    firstSw = swList{j};
                    secondSw = swList{j+1};
                    
                    [flowEntry_temp, flowSrcIp, flowDstIp] = setFlowEntry(prefixList(j), flowEntry, flowTraceTable, i);
                    
                    if strcmp(firstSw, srcEdgeSw)
                        rows = strcmp(swInfTable.SrcNode, srcNodeName);
                        flowEntry_temp.input = swInfTable{rows, {'DstInf'}};
                    else
                        rows = strcmp(swInfTable.SrcNode, g.Nodes.Name{finalPath(end-1)}) & strcmp(swInfTable.DstNode, g.Nodes.Name{finalPath(end)});
                        flowEntry_temp.input = swInfTable{rows, {'DstInf'}};
                    end
            
                    round = j;
                    finalPath_temp = [];
                    
                    [finalPath_temp, swFlowEntryStruct, linkTable] = ...
                        processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                        swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry_temp, finalPath_temp, ...
                        flowStartDatetime(i), firstSw, secondSw, round, dstNodeName, flowSrcIp, flowDstIp);
                
                    finalPath = [finalPath, finalPath_temp];
                end
            else
                prefixLength = flowTraceTable.Prefix(i);
                
                [flowEntry, flowSrcIp, flowDstIp]  = setFlowEntry(prefixLength, flowEntry, flowTraceTable, i);

                rows = strcmp(swInfTable.SrcNode, srcNodeName);
                flowEntry.input = swInfTable{rows, {'DstInf'}};

                round = 3;
                
                [finalPath, swFlowEntryStruct, linkTable] = ...
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
        
        meanFlowTableSize = calculateFlowTableSize(swFlowEntryStruct);
        y_axis_flowTableSize = [y_axis_flowTableSize, meanFlowTableSize];

        [linkThputStruct, meanNetworkThrouput] = ...
            calculateNetworkThrouput(g, linkBwdUnit, ...
            linkThputStruct, eachFlowFinalPath, flowTraceTable, flowStartDatetime, flowEndDatetime);
        
        y_axis_networkThroughput = [y_axis_networkThroughput, meanNetworkThrouput];
        
        doHierarchyCount_list = [doHierarchyCount_list, doHierarchyCount];
    end
    
    allRound_y_axis_flowTableSize = [allRound_y_axis_flowTableSize; y_axis_flowTableSize];
    allRound_y_axis_networkThroughput = [allRound_y_axis_networkThroughput; y_axis_networkThroughput];
end

drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize))
drawNetworkThroughputFigure(x_axis, mean(allRound_y_axis_networkThroughput))


t2 = datetime('now');
disp(t2 - t1)


function [needDohierarchy, swWithTooManyFlowEntry] = ...
    checkFlowTable(tableThreshold, swFlowEntryStruct, needDohierarchy)
    
    flowEntryNum = arrayfun(@swFlowEntryNumber, swFlowEntryStruct);
    rows = (flowEntryNum > tableThreshold);

    if any(rows)
        swWithTooManyFlowEntry = find(rows);
        needDohierarchy = true;
    else
        swWithTooManyFlowEntry = [];
    end
end

function flowEntryNum = swFlowEntryNumber(x)
    global currentFlowTime
    
    if isempty(x.entry)
        flowEntryNum = 0;
    else
        flowEntryNum = length(find(datetime({x.entry.endTime}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= currentFlowTime));
    end
end