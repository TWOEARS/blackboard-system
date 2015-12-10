function [post1, post2] = removeFrontBackConfusion(post1, post2, rotateAngle)
%removeFrontBackConfusion removes front back confusions for a source direction
%
%   USAGE
%       [post1, post2] = removeFrontBackConfusion(post1, post2, rotateAngle)
%
%   INPUT PARAMETERS
%       post1           posteriors before head rotation
%       post2           posteriors after head rotation
%       rotateAngle     head rotation angle
%
%   OUTPUT PARAMETERS
%       post1           posteriors with removed confusion
%       post2           posteriors with removed confusion

if rotateAngle == 0
    return
end

threshold = 0.02;
azimuth = 0:5:355;
nAz = numel(azimuth);

% Identify front-back confusion from post1
post1 = post1(:);
post2 = post2(:);
[pIdx1,pa] = findAllPeaks([0; post1; 0]);
pIdx1 = pIdx1 - 1;
pIdx1 = pIdx1(pa > threshold);
[fbIdx1, fbAz1] = find_front_back_idx(pIdx1);

% Identify front-back confusion from post2
[pIdx2,pa] = findAllPeaks([0; post2; 0]);
pIdx2 = pIdx2 - 1;
pIdx2 = pIdx2(pa > threshold);
[fbIdx2, fbAz2] = find_front_back_idx(pIdx2);

% Check if any front-back confusion from post1 should be removed
srcAz = [];
for n = 1:size(fbIdx1,1)

    % Set prob of both front-back angles to the max
    p = max(post1(fbIdx1(n,:)));
    fbAzNew = mod(fbAz1(n,:) - rotateAngle, 360);
    for m = 1:2
        %if min(abs(azimuth(pIdx2) - fbAzNew(m))) > 5
        if post2(azimuth==fbAzNew(m)) < threshold
            idx = fbIdx1(n,m)-1:fbIdx1(n,m)+1;
            idx = idx(idx>=1);
            idx = idx(idx<=nAz);
            post1(idx) = 0;
            post1(fbIdx1(n,mod(m,2)+1)) = p;
        else
            srcAz = [srcAz; fbAzNew(m)];
        end
    end
        
end

% Check if any front-back confusion from post2 should be removed
for n = 1:size(fbIdx2,1)

    % Set prob of both front-back angles to the max
    p = max(post2(fbIdx2(n,:)));
    fbAzNew = mod(fbAz2(n,:) + rotateAngle, 360);
    for m = 1:2
        if (isempty(fbAz2(n,mod(m,2)+1)) || isempty(post1(azimuth==fbAzNew(m))))
            continue;
        end
        
        %if sum(fbAz2(n,mod(m,2)+1)==srcAz)>0 || min(abs(azimuth(pIdx1) - fbAzNew(m))) > 5
        if sum(fbAz2(n,mod(m,2)+1)==srcAz)>0 || post1(azimuth==fbAzNew(m)) < threshold
            idx = fbIdx2(n,m)-1:fbIdx2(n,m)+1;
            idx = idx(idx>=1);
            idx = idx(idx<=nAz);
            post2(idx) = 0;
            post2(fbIdx2(n,mod(m,2)+1)) = p;
        end
    end
        
end


%------------
function [fbIdx, fbAz] = find_front_back_idx(pIdx)


azimuth = 0:5:355;


fbIdx = [];
fbAz = [];
for m = 1:length(pIdx)-1
    
    for n = m+1:length(pIdx)
        
        az1 = azimuth(pIdx(m));
        az2 = azimuth(pIdx(n));
        if abs(az1 + az2 - 180) <= 5 || abs(az1 + az2 - 540) <= 5
            fbIdx = [fbIdx; [pIdx(m) pIdx(n)]];
            fbAz = [fbAz; [az1 az2]];
        end
        
    end
    
end

