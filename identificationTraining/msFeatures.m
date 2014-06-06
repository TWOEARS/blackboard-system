function features = msFeatures( param, rmBlock )

% TODO: determine which channel to use!
s = .5 * rmBlock(:,:,1) + .5 * rmBlock(:,:,2);
features = [mean( s, 2 ); std( s, 0, 2 )];
for i = 1:param.derivations
    s = s(:,2:end) - s(:,1:end-1);
    features = [features; mean( s, 2 ); std( s, 0, 2 )];
end
