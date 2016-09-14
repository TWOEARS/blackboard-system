function idScores = getIdDecisions( identityHypotheses )

idScores = struct();
for ii = numel( identityHypotheses ) : -1 : 1
    off = identityHypotheses(ii).sndTmIdx;
    for jj = 1 : numel( identityHypotheses(ii).data )
        on = max( 0, off - identityHypotheses(ii).data(jj).concernsBlocksize_s );
        d = identityHypotheses(ii).data(jj).d;
        label = identityHypotheses(ii).data(jj).label;
        if isfield( idScores, label )
            idScores.(label).x = [on idScores.(label).x];
            idScores.(label).y = [d idScores.(label).y];
        else
            idScores.(label).x = [on off];
            idScores.(label).y = [d d];
        end
    end
end
