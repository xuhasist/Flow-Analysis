function drawFlowTableSizeFigure_fixedPrefix(x_axis, y_axis_flowTableSize, i, frequency, x_label)
    x = x_axis;
    y = y_axis_flowTableSize;
    %x = (1:32);
    %y = randi(50, 32, 1);
    
    plot(x, y, 'Marker', 's')
    % 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b'
    
    %grid on

    xlabel(x_label)
    ylabel('Average Number of Flow Rules')

    %set(gca, 'FontSize', 8)
    %set(gcf, 'PaperUnits', 'inches')
    %set(gcf, 'PaperPosition', [0 0 10 6])

    xticks(x)
    %yticks(floor(min(y)/10)*10: 10: ceil(max(y)/10)*10)
    
    print(['figure/flowTableSize/flowTableSizeFigure_', int2str(frequency), '_', int2str(i)], '-dpng')
end