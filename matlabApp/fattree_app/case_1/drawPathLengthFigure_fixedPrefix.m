function drawPathLengthFigure_fixedPrefix(x_axis, y_axis_pathLength, frequency, x_label)
    x = x_axis;
    y = y_axis_pathLength;
    
    plot(x, y, 'Marker', 's')
    
    xlabel(x_label)
    ylabel('Average Length of Flow Path')

    xticks(x)
    
    print(['figure/pathLength/pathLengthFigure_', int2str(frequency)], '-dpng')
end