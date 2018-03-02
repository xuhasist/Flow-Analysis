function drawPathLengthFigure(x_axis, y_axis_pathLength, y_axis_pathLength_perFlow, frequency, x_label)
    x = x_axis;
    y = y_axis_pathLength;

    plot(x, y, 'Marker', 's')
    
    hold on
    
    y = y_axis_pathLength_perFlow;
    
    plot(x, y, '--', 'Marker', 'o')
    
    hold off
    
    legend('clustering', 'per-flow', 'Location', 'southeast')

    xlabel(x_label)
    ylabel('Average Length of Flow Path')

    xticks(x)
    
    print(['figure/pathLength/pathLengthFigure_', int2str(frequency)], '-dpng')
end