function tableThresholdClustering_changeFlowNum()
    clearvars -except

    t1 = datetime('now');

    global currentFlowTime

    hostAvg = 50;
    hostSd = 5;

    linkBwdUnit = 10^3; %10Kbps
    tableThreshold = 50;

    startFlowNumber = 1000;
    endFlowNumber = 5000;
    x_axis = startFlowNumber:500:endFlowNumber;
    x_label = 'Number of Flows';

    allRound_y_axis_flowTableSize_1 = [];
    allRound_y_axis_flowTableSize_2 = [];
    allRound_y_axis_flowTableSize_3 = [];
    allRound_y_axis_flowTableSize_4 = [];
    allRound_y_axis_flowTableSize_5 = [];
    allRound_y_axis_flowTableSize_6 = [];
    allRound_y_axis_flowTableSize_7 = [];
    allRound_y_axis_flowTableSize_8 = [];
    allRound_y_axis_flowTableSize_perFlow = [];

    allRound_y_axis_networkThroughput = [];
    allRound_y_axis_networkThroughput_perFlow = [];

    roundNumber = 3;
    for frequency = 1:roundNumber
        % fat tree
        k = 4;
        [swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP] = ...
            createFatTreeTopo(k, hostAvg, hostSd);

        % AS topo
        %eachAsEdgeSwNum = 2;
        %[swNum, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeTable, hostNum, IP] = ...
            %createAsTopo_random(eachAsEdgeSwNum, hostAvg, hostSd);


        swDistanceVector = distances(g, 'Method', 'unweighted');
        swDistanceVector = swDistanceVector(1:swNum, 1:swNum);

        % for as topo
        %rows = strcmp(nodeTable.Type, 'RT_NODE');
        %swDistanceVector(rows, rows) = 0;

        y_axis_flowTableSize_1 = [];
        y_axis_flowTableSize_2 = [];
        y_axis_flowTableSize_3 = [];
        y_axis_flowTableSize_4 = [];
        y_axis_flowTableSize_5 = [];
        y_axis_flowTableSize_6 = [];
        y_axis_flowTableSize_7 = [];
        y_axis_flowTableSize_8 = [];
        y_axis_flowTableSize_perFlow = [];

        y_axis_networkThroughput = [];
        y_axis_networkThroughput_perFlow = [];

        doHierarchyCount_list = [];

        for flowNum = startFlowNumber:500:endFlowNumber
            [swInfTable, swFlowEntryStruct, hostIpTable, linkTable, linkThputStruct, flowTraceTable, flowSequence] = ...
                setVariables(swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP, flowNum);

            % remove mice flow
            flowStartDatetime = datetime(flowTraceTable.StartDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            flowEndDatetime = datetime(flowTraceTable.EndDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

            rows = (flowEndDatetime - flowStartDatetime < seconds(1));
            flowTraceTable(rows, :) = [];

            flowStartDatetime(rows) = [];
            flowEndDatetime(rows) = [];


            [meanFlowTableSize_perFlow, meanNetworkThrouput_perFlow] = ...
                perFlowClustering(flowStartDatetime, flowEndDatetime, linkBwdUnit, ...
                hostIpTable, flowTraceTable, swFlowEntryStruct, g, swInfTable, linkTable, linkThputStruct);


            eachFlowFinalPath = {};
            linkPreLower = [];
            needDohierarchy = false;
            doHierarchyCount = 0;

            [idx, group_num] = doKmeans(flowSequence);

            flowTraceTable.Group = repmat(-1, size(flowTraceTable, 1), 1);
            flowTraceTable.Prefix = repmat(16, size(flowTraceTable, 1), 1);
            flowTraceTable.HierarchicalGroup = zeros(size(flowTraceTable, 1), 1);
            flowTraceTable.MiddleSrcSw = repmat({{}}, size(flowTraceTable, 1), 1);
            flowTraceTable.MiddleDstSw = repmat({{}}, size(flowTraceTable, 1), 1);
            flowTraceTable.HierarchicalPrefix = zeros(size(flowTraceTable, 1), 1);
            flowTraceTable.ClusterPort = zeros(size(flowTraceTable, 1), 1);

            flowTraceTable = similarityClustering_tableThreshold(g, hostIpTable, swInfTable, flowTraceTable, idx, group_num);

            %preCheckTableTime = flowStartDatetime(1);
            for i = 1:size(flowTraceTable, 1)
                i

                [srcNodeName, dstNodeName, flowStartStrtime, flowEndStrtime, flowRate, flowTraceTable, flowEntry] = ...
                    setFlowInfo(flowStartDatetime(i), flowEndDatetime(i), linkBwdUnit, hostIpTable, flowTraceTable, i);

                currentFlowTime = flowStartDatetime(i);

                %{
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
                %}

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
                    prefixLength = flowTraceTable.Prefix(i);

                    [flowEntry, flowSrcIp, flowDstIp]  = setFlowEntry(prefixLength, flowEntry, flowTraceTable, i);

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

                [needDohierarchy, swWithTooManyFlowEntry] = ...
                        checkFlowTable(tableThreshold, swFlowEntryStruct, needDohierarchy, finalPath);

                if needDohierarchy
                    doHierarchyCount = doHierarchyCount + 1;
                    flowTraceTable = hierarchicalClustering_tableThreshold(tableThreshold, swWithTooManyFlowEntry, g, swDistanceVector, hostIpTable, swInfTable, eachFlowFinalPath, flowTraceTable);

                    needDohierarchy = false;
                    swFlowEntryStruct = removeAllFlowEntry(swFlowEntryStruct, flowStartDatetime(i));
                end

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

            y_axis_flowTableSize_perFlow = [y_axis_flowTableSize_perFlow, meanFlowTableSize_perFlow];
            y_axis_networkThroughput_perFlow = [y_axis_networkThroughput_perFlow, meanNetworkThrouput_perFlow];

            doHierarchyCount_list = [doHierarchyCount_list, doHierarchyCount];

            filename = ['memory/memory_', int2str(frequency), '_', int2str(flowNum)];
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

        allRound_y_axis_flowTableSize_perFlow = [allRound_y_axis_flowTableSize_perFlow; y_axis_flowTableSize_perFlow];
        allRound_y_axis_networkThroughput_perFlow = [allRound_y_axis_networkThroughput_perFlow; y_axis_networkThroughput_perFlow];

        if frequency == 1
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_1, allRound_y_axis_flowTableSize_perFlow, 1, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_2, allRound_y_axis_flowTableSize_perFlow, 2, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_3, allRound_y_axis_flowTableSize_perFlow, 3, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_4, allRound_y_axis_flowTableSize_perFlow, 4, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_5, allRound_y_axis_flowTableSize_perFlow, 5, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_6, allRound_y_axis_flowTableSize_perFlow, 6, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_7, allRound_y_axis_flowTableSize_perFlow, 7, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_8, allRound_y_axis_flowTableSize_perFlow, 8, frequency, x_label)

            drawNetworkThroughputFigure(x_axis, allRound_y_axis_networkThroughput, allRound_y_axis_networkThroughput_perFlow, frequency, x_label)
        else
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_1), mean(allRound_y_axis_flowTableSize_perFlow), 1, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_2), mean(allRound_y_axis_flowTableSize_perFlow), 2, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_3), mean(allRound_y_axis_flowTableSize_perFlow), 3, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_4), mean(allRound_y_axis_flowTableSize_perFlow), 4, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_5), mean(allRound_y_axis_flowTableSize_perFlow), 5, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_6), mean(allRound_y_axis_flowTableSize_perFlow), 6, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_7), mean(allRound_y_axis_flowTableSize_perFlow), 7, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_8), mean(allRound_y_axis_flowTableSize_perFlow), 8, frequency, x_label)

            drawNetworkThroughputFigure(x_axis, mean(allRound_y_axis_networkThroughput), mean(allRound_y_axis_networkThroughput_perFlow), frequency, x_label)
        end
    end

    t2 = datetime('now');
    disp(t2 - t1)

    save('memory/final')
end

function [needDohierarchy, swWithTooManyFlowEntry] = ...
    checkFlowTable(tableThreshold, swFlowEntryStruct, needDohierarchy, finalPath)

    checkedSwitch = finalPath(2:end-1);
    
    flowEntryNum = arrayfun(@swFlowEntryNumber, swFlowEntryStruct(checkedSwitch));
    rows = (flowEntryNum > tableThreshold);

    if any(rows)
        swWithTooManyFlowEntry = checkedSwitch(rows);
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
