function drawFlowTableSizeFigure_fixedPrefix(x_axis, y_axis_flowTableSize, i, frequency, x_label)
    x = x_axis;
    y = y_axis_flowTableSize;
    
    plot(x, y, 'Marker', 's')
    
    xlabel(x_label)
    ylabel('Average Number of Flow Rules')

    xticks(x)
    
    print(['figure/flowTableSize/flowTableSizeFigure_', int2str(frequency), '_', int2str(i)], '-dpng')
end