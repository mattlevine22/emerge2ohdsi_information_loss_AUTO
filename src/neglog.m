function goo = neglog(foo)
%% Please note that this function only makes sense to use when data are not between -1 and 1 (zero is OK though).
% in those cases, you get a negative exponent, and things dont work!!!
b = sum(abs(foo)>0 & abs(foo)<1);
if b>0
    warning('Improper use case of neglog...input contains values between 0 and 1 or 0 and -1.')
    warning('Rounding these cases to 1 or -1')
    foo(foo<1 & foo>0) = 1;
    foo(foo>-1 & foo<0) = -1;
    b
    b/length(foo)
end
	goo = ((foo > 0).*log10(foo))+(-(foo<0).*log10(-foo));
	goo(foo==0) = 0;

end
