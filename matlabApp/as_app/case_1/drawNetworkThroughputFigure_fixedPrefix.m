function drawNetworkThroughputFigure_fixedPrefix(x_axis, y_axis_networkThroughput, frequency, x_label)
    x = x_axis;
    y = y_axis_networkThroughput;
    y = y/(10^3);

    plot(x, y, 'Marker', 's')

    xlabel(x_label)
    %ylabel('Average Network Throuput (Kbps)')
    ylabel('Average Network Throuput (Mbps)')

    xticks(x)
    %yticks(floor(min(y)/10)*10: ceil(max(y)/10)*10)
    
    print(['figure/networkThroughput/networkThroughputFigure', '_', int2str(frequency)], '-dpng')
end