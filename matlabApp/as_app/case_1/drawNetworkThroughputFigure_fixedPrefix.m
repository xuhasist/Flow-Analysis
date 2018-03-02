function drawNetworkThroughputFigure_fixedPrefix(x_axis, y_axis_networkThroughput, frequency, x_label)
    x = x_axis;
    y = y_axis_networkThroughput;
    y = y/(10^3);

    plot(x, y, 'Marker', 's')

    xlabel(x_label)
    ylabel('Average Network Throuput (Mbps)')

    xticks(x)
    
    print(['figure/networkThroughput/networkThroughputFigure_', int2str(frequency)], '-dpng')
end