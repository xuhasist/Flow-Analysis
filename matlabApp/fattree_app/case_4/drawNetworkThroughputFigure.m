function drawNetworkThroughputFigure(x_axis, y_axis_networkThroughput, y_axis_networkThroughput_perFlow, frequency, x_label)
    x = x_axis;
    y = y_axis_networkThroughput;
    y = y/(10^3);

    plot(x, y, 'Marker', 's')
    
    hold on
    
    y = y_axis_networkThroughput_perFlow;
    y = y/(10^3);
    
    plot(x, y, '--', 'Marker', 'o')
    
    hold off
    
    legend('clustering', 'per-flow', 'Location', 'southeast')

    xlabel(x_label)
    %ylabel('Average Network Throuput (Kbps)')
    ylabel('Average Network Throuput (Mbps)')

    xticks(x)
    %yticks(floor(min(y)/10)*10: ceil(max(y)/10)*10)
    
    print(['figure/networkThroughput/networkThroughputFigure', '_', int2str(frequency)], '-dpng')
end