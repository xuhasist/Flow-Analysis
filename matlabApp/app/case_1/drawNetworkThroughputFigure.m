function drawNetworkThroughputFigure(x_axis, y_axis_networkThroughput)
    x = x_axis;
    y = y_axis_networkThroughput;

    plot(x, y, 'Marker', 's')

    xlabel('Prefix Length (bits)')
    ylabel('Average Network Throuput (Kbps)')

    %xticks(min(x): max(x))
    %yticks(floor(min(y)/10)*10: ceil(max(y)/10)*10)
    
    print('networkThroughputFigure', '-dpng')
end