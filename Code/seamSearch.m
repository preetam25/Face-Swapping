clear()
tic;

%% Load Image

I = imread('../Data/Aaron_Eckhart_0001.jpg');
[m, n] = size(rgb2gray(I));
P = uint8(rgb2gray(I));

%% Compute gradient

[Gx, Gy] = gradient(double(rgb2gray(I)));
p = 2;
G = (abs(Gx)).^p+(abs(Gy)).^p;
G = G.^(1/p);
G = G - min(G(:));
G = G/max(G(:));
G = reshape(G, [1, m*n]);
% G = G + 0.01; % Optional - explained in the Report/Addendum.pdf


%% Update coordinate values

[status, cmdout] = system('cat flandmark.txt');
cmdout = strsplit(cmdout);
left_eye = [0,0];
left_mouth = [0,0];
right_eye = [0,0];
right_mouth = [0,0];
left_eye(1) = str2double(cmdout(11));
left_eye(2) = str2double(cmdout(12));
left_mouth(1) = str2double(cmdout(7));
left_mouth(2) = str2double(cmdout(8));
right_eye(1) = str2double(cmdout(13));
right_eye(2) = str2double(cmdout(14));
right_mouth(1) = str2double(cmdout(9));
right_mouth(2) = str2double(cmdout(10));
y = str2double(cmdout(17));
x = str2double(cmdout(18));
height = str2double(cmdout(19));
width = str2double(cmdout(20));

bbox_x = [y, y+height, y+height, x];
bbox_y = [x, x, x+width, x+width];

%% Setup

mid_eye = (right_eye+left_eye)/2 - [20, 0];
head = int64(mid_eye(1));
cut = int64(mid_eye(2));
mid_mouth = (right_mouth+left_mouth)/2 + [10, 0];
mouth = int64(mid_mouth(1));
start  = (head-3)*n+cut;
stop = start-1;

%% Graph construction

s = [];
t = [];
w = [];

for i = 1:m*n
   if(~inpolygon(rem(i,n), fix(i/n)+1, [left_eye(2), right_eye(2)+20, right_mouth(2), left_mouth(2)], [left_eye(1), right_eye(1), right_mouth(1), left_mouth(1)]))
    if(inpolygon(rem(i,n), fix(i/n)+1, bbox_x, bbox_y))
        
        if(i > n)
           s = [s, i];
           t = [t, i-n];
           w = [w, G(i-n)];
       end
       if(rem(i,n)~=0)
           s = [s, i];
           t = [t, i+1];
           w = [w, G(i+1)];
       end
       if(i<n*m-n+1)
           s = [s, i];
           t = [t, i+n];
           w = [w, G(i+n)];
       end
       if(rem(i,n)~=1 && rem(i,n)~=cut)
          s = [s, i];
          t = [t, i-1];
          w = [w, G(i-1)];
       end
       if(rem(i,n)~=1 && rem(i,n)==cut && fix(i/n)+1>mouth)
          s = [s, i];
          t = [t, i-1];
          w = [w, G(i-1)];
       end
    end 
   end
end

pathregion = digraph(s, t, w);

%% Finding the optimal seam

[route, d] = shortestpath(pathregion, start, stop);
[~, seam] = size(route);
for i = 1:seam
   I(fix(route(i)/n)+1, rem(route(i),n),:) = [255, 0, 0]; 
end
figure,
imshow(I);