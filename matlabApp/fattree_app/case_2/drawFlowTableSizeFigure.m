function drawFlowTableSizeFigure(x_axis, y_axis_flowTableSize, y_axis_flowTableSize_perFlow, i, frequency, x_label)
    x = x_axis;
    y = y_axis_flowTableSize;
    
    plot(x, y, 'Marker', 's')
    
    hold on
    
    y = y_axis_flowTableSize_perFlow;
    
    plot(x, y, '--', 'Marker', 'o')
    
    hold off
    
    legend('clustering', 'per-flow', 'Location', 'southeast')
    
    xlabel(x_label)
    ylabel('Average Number of Flow Rules')

    xticks(x)
    
    print(['figure/flowTableSize/flowTableSizeFigure_', int2str(frequency), '_', int2str(i)], '-dpng')
end