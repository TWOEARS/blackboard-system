function fig = plotIdentificationScene( axh, labels, onOffsets, identityHypotheses, timeRange )

cla( axh, 'reset' );
set( axh, 'YLim', [0 1.1], 'XLim', timeRange );
hold( axh,'all' );
xlabel( axh, 'time (s)' );

eventInTimeRange = ...
    ((onOffsets(:,1) >= timeRange(1)) & (onOffsets(:,1) <= timeRange(2)))  | ...
    ((onOffsets(:,2) >= timeRange(1)) & (onOffsets(:,2) <= timeRange(2)));
labelsTrunc = labels(eventInTimeRange);
onOffsetsTrunc = onOffsets(eventInTimeRange,:);
for ii = 1 : length(labelsTrunc)
    on = onOffsetsTrunc(ii,1);
    off = onOffsetsTrunc(ii,2);
    h = line( [on on off off], [0 1 1 0], ...
          'DisplayName', 'Ground Truth', 'LineWidth', 2, 'Color', [0 0 0], 'Parent', axh );
    set( get( get( h, 'Annotation' ), 'LegendInformation' ), 'IconDisplayStyle', 'off' );  
    text( onOffsetsTrunc(ii,1), 1.03, labelsTrunc{ii}, 'Parent', axh );
end

idScores = struct();
for ii = numel( identityHypotheses ) : -1 : 1
    off = identityHypotheses(ii).sndTmIdx;
    for jj = 1 : numel( identityHypotheses(ii).data )
        on = max( 0, off - identityHypotheses(ii).data(jj).concernsBlocksize_s );
        score = identityHypotheses(ii).data(jj).p;
        label = identityHypotheses(ii).data(jj).label;
        if isfield( idScores, label )
            idScores.(label).x = [on idScores.(label).x];
            idScores.(label).y = [score idScores.(label).y];
        else
            idScores.(label).x = [on off];
            idScores.(label).y = [score score];
        end
    end
end

idLabels = sort( fieldnames( idScores ) );
for ii = 1 : numel( idLabels )
    plot( idScores.(idLabels{ii}).x, idScores.(idLabels{ii}).y, ...
          'Parent', axh, 'DisplayName', idLabels{ii}, 'LineWidth', 2, 'LineStyle', '--' );
end

legend1 = legend( axh, 'show' );
%set( legend1, 'Location', 'EastOutside' );

hold( axh, 'off' );

