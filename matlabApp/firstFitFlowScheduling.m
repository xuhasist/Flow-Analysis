function paths = firstFitFlowScheduling(topo, elephantFlow, linkInfo)
    %sort elephantFlow in descending order of the predicted flow demand
    Ffields = fieldnames(elephantFlow);
    Fcell = struct2cell(elephantFlow);
    sz = size(Fcell);
    Fcell = reshape(Fcell, sz(1), []);
    Fcell = Fcell';
    Fcell = sortrows(Fcell, 3, 'descend');
    Fcell = reshape(Fcell', sz);
    elephantFlow = cell2struct(Fcell, Ffields, 1);
    
    clearvars Ffields Fcell sz
    
    for i = 1:length(elephantFlow)
        for j = 1:length(elephantFlow(i).path)-1
            pathIndex = findedge(topo, elephantFlow(i).path(j), elephantFlow(i).path(j+1));
            if linkInfo.load(pathIndex) > elephantFlow(i).rate
                linkInfo.load(pathIndex) = linkInfo.load(pathIndex) - elephantFlow(i).rate;
            else
                linkInfo.load(pathIndex) = 0;
            end
        end
    end
    
    adj = adjacency(topo);
    paths = {};
    for i = 1:length(elephantFlow)
        bestPath.congest = 1000;
        bestPath.pth = '';
        s = findnode(topo, elephantFlow(i).s);
        t = findnode(topo, elephantFlow(i).t);
        pth = findpaths(adj, ones(1, size(adj,1)), [], s, t);
        for j = 1:length(pth)
            %find bottleneck link
            bottleneckLinkLoad = 1000;
            bottleneckLinkWeight = 0;
            for k = 1:length(pth{j})-1
                pathIndex = findedge(topo, pth{j}(k), pth{j}(k+1));
                if linkInfo.load(pathIndex) < bottleneckLinkLoad
                    bottleneckLinkLoad = linkInfo.load(pathIndex);
                    bottleneckLinkWeight = linkInfo.weight(pathIndex);
                end
            end

            congest = (elephantFlow(i).rate + bottleneckLinkLoad) / bottleneckLinkWeight;
            if congest < bestPath.congest
               bestPath.pth = pth{j};
               bestPath.congest = congest;
            end
        end
        paths = [paths; bestPath];
    end
end