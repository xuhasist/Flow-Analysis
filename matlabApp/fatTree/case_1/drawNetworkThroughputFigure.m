function drawNetworkThroughputFigure(x_axis, y_axis_networkThroughput, frequency)
    x = x_axis;
    y = y_axis_networkThroughput;
    y = y/(10^3);

    plot(x, y, 'Marker', 's')

    xlabel('Prefix Length (bits)')
    %ylabel('Average Network Throuput (Kbps)')
    ylabel('Average Network Throuput (Mbps)')

    %xticks(min(x): max(x))
    %yticks(floor(min(y)/10)*10: ceil(max(y)/10)*10)
    
    print(['figure/networkThroughput/networkThroughputFigure', '_', int2str(frequency)], '-dpng')
end