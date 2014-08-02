function double_arrow(class)


P =[NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,NaN,NaN,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,2,1,1,1,2,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,2,1,1,1,1,1,2,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,2,2,2,2,1,2,2,2,2,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,2,2,2,2,1,2,2,2,2,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,2,1,1,1,1,1,2,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,2,1,1,1,2,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,2,NaN,NaN,NaN,NaN,NaN,NaN;
    NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,NaN,NaN,NaN,NaN,NaN,NaN,NaN;];
if class==1;
P=rot90(P);
else
end
set(gcf,'Pointer','custom','PointerShapeCData',P,'PointerShapeHotSpot',[9 9]);