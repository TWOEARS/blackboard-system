function features = msFeatures( param, rmBlock )

s = rmBlock(:,:,2);
features = [mean( s, 2 ); std( s, 0, 2 )];
for i = 1:param.derivations
    s = s(:,2:end) - s(:,1:end-1);
    features = [features; mean( s, 2 ); std( s, 0, 2 )];
end
