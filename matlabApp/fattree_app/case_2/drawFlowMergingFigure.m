function drawFlowMergingFigure(x_axis, y_axis_doHierarchyCount, frequency, x_label)
    x = x_axis;
    y = y_axis_doHierarchyCount;
    
    plot(x, y, 'Marker', 's')
    
    xlabel(x_label)
    ylabel('Number of Flow Merging')

    xticks(x)
    
    print(['figure/flowMerging/flowMergingFigure_', int2str(frequency)], '-dpng')
end