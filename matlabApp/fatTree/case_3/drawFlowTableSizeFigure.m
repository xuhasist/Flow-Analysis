function drawFlowTableSizeFigure(x_axis, y_axis_flowTableSize, y_axis_flowTableSize_perFlow, i, frequency)
    x = x_axis;
    y = y_axis_flowTableSize;
    %x = (1:32);
    %y = randi(50, 32, 1);
    
    plot(x, y, 'Marker', 's')
    
    hold on
    
    y = y_axis_flowTableSize_perFlow;
    plot(x, y, '--', 'Marker', 'o')
    
    hold off
    
    legend('clustering', 'per-flow', 'Location', 'southeast')
    
    % 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b'
    
    %grid on

    xlabel('Prefix Length (bits)')
    ylabel('Average Number of Flow Rules')

    %set(gca, 'FontSize', 8)
    %set(gcf, 'PaperUnits', 'inches')
    %set(gcf, 'PaperPosition', [0 0 10 6])

    %xticks(min(x): max(x))
    %yticks(floor(min(y)/10)*10: 10: ceil(max(y)/10)*10)
    
    print(['figure/flowTableSize/flowTableSizeFigure_', int2str(frequency), '_', int2str(i)], '-dpng')
end