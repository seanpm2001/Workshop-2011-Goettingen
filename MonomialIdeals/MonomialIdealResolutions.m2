needsPackage ("SimplicialComplexes");
needsPackage ("ChainComplexExtras");


newPackage (
  "MonomialIdealResolutions",
  Version=>"0.1",
  Date => "march 2011",
  Authors => {{Name => "Eduardo Saenz De Cabezon Irigara", Email => "eduardo.saenz-de-cabezon@unirioja.es"},
              {Name => "Oscar Fernandez-Ramos", Email => "caribefresno@gmail.com"},
              {Name => "Christof Söger", Email => "csoeger@uos.de"}},
  Headline => "various methods for working with resolutions for monomial ideals",
  DebuggingMode => false
)

needsPackage ("SimplicialComplexes");
needsPackage ("ChainComplexExtras");
-------------------
-- Exports
-------------------
export {      
  isStable,
  isElement,
  isGenericMonIdeal,
  EK,
  EKResolution,
  scarf,  
  isSQStable,
  AHH,
  AHHResolution,
  simplicialResolutionDifferential,
  simplicialResolution,
  isResolution
}

-------------------
-- Exported Code
-------------------
   
isGenericMonIdeal=method();
isGenericMonIdeal(MonomialIdeal) := I->(
     local l; 
     flag:=true;
     ex:=apply(I_*,g->(flatten exponents g));
   --  print VerticalList ex;
     apply(support I,v->(
	                l=select(apply(ex,e->e_(index v)),a->a!=0);
			if length (unique l) !=length l then flag=false;
			)      
	  );
     flag     
) 

scarf=method();
scarf(MonomialIdeal):= I -> (
   S:=drop(subsets(numgens I),1);
   faces:={};
   P:=partition(s->lcmMon(apply (s,i->flatten exponents I_i)),S);
   apply(keys P,k->if #(P#k)==1 then faces=faces|P#k); 
   v:=getSymbol "v";
   R:=QQ[v_1..v_(length faces-1)];
   simplicialComplex apply(faces,f->product(apply(f,i->R_i)))           
)


EK = method()
EK(ZZ,MonomialIdeal):= (n,I)->(
   --- create the nth differential in Eliahou-Kervaire's resolution
   retVal := Nothing;
   if (n == 0) then 
      retVal = gens I
   else
   {
      R := ring I;
      symbolsList:=admissibleSymbols(I);
      sourceList:=symbolsList_(positions (symbolsList,i->first degree(promote(i_0,R))==n));
      targetList:=symbolsList_(positions (symbolsList,i->first degree(promote(i_0,R))==n-1));
      getCoeff := (i,j) -> if (liftable(sourceList_j_0//targetList_i_0,R) and (targetList_i_1==sourceList_j_1)) then
                             (-1)^(position(positions(flatten exponents(sourceList_j_0),r->r!=0),s->s==position(first entries vars R,t->t==sourceList_j_0//targetList_i_0)))
			   else if  (liftable(sourceList_j_0//targetList_i_0,R) and (canonicalDecomp(lift(sourceList_j_0//targetList_i_0,R)*sourceList_j_1,first entries gens I)==targetList_i_1)) then
                             (-1)^(1+position(positions(flatten exponents(sourceList_j_0),r->r!=0),s->s==position(first entries vars R,t->t==sourceList_j_0//targetList_i_0)))
			   else 0_R;
       myFn := (i,j) -> (tempElt := sourceList_j_0 / targetList_i_0;
	    	      	 if (liftable (tempElt,R)) then tempElt2:=(lift(tempElt,R)*sourceList_j_1)//canonicalDecomp(lift(tempElt,R)*sourceList_j_1,first entries gens I);
	                if (liftable(tempElt,R) and (targetList_i_1==sourceList_j_1) ) then  getCoeff(i,j)*lift(tempElt,R)
			  else if (liftable(tempElt,R) and (targetList_i_1==canonicalDecomp(lift(tempElt,R)*sourceList_j_1,first entries gens I))) then 
			       getCoeff(i,j)*(tempElt2)
			 else 0_R);      
      retVal = map(R^(-apply(targetList, i -> (degree(promote(i_1,R)*promote(i_0,R))))), R^(-apply(sourceList, i -> (degree(promote(i_1,R)*promote(i_0,R))))), myFn);
   };
   retVal
)

EKResolution=method();
EKResolution(MonomialIdeal):=(I)->(
    chainComplex(apply((0..numgens(ring I)-1), i -> EK(i,I)))
)

isElement = method();
isElement(RingElement, MonomialIdeal) := Boolean => (f,I) -> (
  all (exponents f,
    fexp -> any(I_*, g -> all(fexp, flatten exponents g, (fe,ge) -> fe >= ge ))
  )
);


-- PURPOSE: check if a monomial ideal is stable
-- INPUT:   a monomial ideal
-- OUTPUT:  true if the ideal is stable and false otherwise. 
-- COMMENT: checks only for the ordering in which the variables appear in the ring  

isStable = method();
isStable(MonomialIdeal) := Boolean => (I) -> (
  S:=ring I;
  all( I_*, g-> ( 
    mv:=maxVar(g); f:=lift(g/S_mv,S);
    all(mv, j -> isElement(f*S_j,I))
    )
  )
);

--The following is the Squarefree version (SQ) of isStable.
--NOTE: squarefree stable is different from squarefree and stable

isSQStable = method();
isSQStable(MonomialIdeal) := Boolean => (I) -> (
  S:=ring I;
  not any( I_*, g-> (
    mv:=maxVar(g); vars:=positions((first exponents g)_{0..mv},i->i==0);f:=lift(g/S_mv,S);
    any(vars, j -> not isElement(f*S_j,I))
    )
  )
);


--Aramova-herzog-Hibi gave a resolution for squarefree stable monomial ideals
--which basically corresponds to Eliahou-kervaire's for stable ideals

AHH = method()
AHH(ZZ,MonomialIdeal):= (n,I)->(
   --- create the nth differential in Aramova-Herzog's resolution
   retVal := Nothing;
   if (n == 0) then 
      retVal = gens I
   else
   {
      R := ring I;
      symbolsList:=admissibleSQSymbols(I);
      sourceList:=symbolsList_(positions (symbolsList,i->first degree(promote(i_0,R))==n));
      targetList:=symbolsList_(positions (symbolsList,i->first degree(promote(i_0,R))==n-1));
      getCoeff := (i,j) -> if (liftable(sourceList_j_0//targetList_i_0,R) and (targetList_i_1==sourceList_j_1)) then
                             (-1)^(position(positions(flatten exponents(sourceList_j_0),r->r!=0),s->s==position(first entries vars R,t->t==sourceList_j_0//targetList_i_0)))
			   else if  (liftable(sourceList_j_0//targetList_i_0,R) and (canonicalDecomp(lift(sourceList_j_0//targetList_i_0,R)*sourceList_j_1,first entries gens I)==targetList_i_1)) then
                             (-1)^(1+position(positions(flatten exponents(sourceList_j_0),r->r!=0),s->s==position(first entries vars R,t->t==sourceList_j_0//targetList_i_0)))
			   else 0_R;
       myFn := (i,j) -> (tempElt := sourceList_j_0 / targetList_i_0;
	    	      	 if (liftable (tempElt,R)) then tempElt2:=(lift(tempElt,R)*sourceList_j_1)//canonicalDecomp(lift(tempElt,R)*sourceList_j_1,first entries gens I);
	                if (liftable(tempElt,R) and (targetList_i_1==sourceList_j_1) ) then  getCoeff(i,j)*lift(tempElt,R)
			  else if (liftable(tempElt,R) and (targetList_i_1==canonicalDecomp(lift(tempElt,R)*sourceList_j_1,first entries gens I))) then 
			       getCoeff(i,j)*(tempElt2)
			 else 0_R);      
      retVal = map(R^(-apply(targetList, i -> (degree(promote(i_1,R)*promote(i_0,R))))), R^(-apply(sourceList, i -> (degree(promote(i_1,R)*promote(i_0,R))))), myFn);
   };
   retVal
)

AHHResolution=method();
AHHResolution(MonomialIdeal):=(I)->(
     R:=ring(I);
     maxlevel:=length(R_*)-max(apply(I_*,i->(maxVar(i)+1-first degree(i))))-1;
     chainComplex(apply((0..maxlevel), i -> AHH(i,I)))
)



simplicialResolutionDifferential=method();

simplicialResolutionDifferential(ZZ,MonomialIdeal,SimplicialComplex):=(n,I,C) -> (
    retVal := Nothing;
    if (n == 0) then 
      retVal = gens I
    else
    {
     R:=ring I;
     sourceL:=flatten apply(first entries faces(n,C),i->exponents(i));
     targetL:=flatten apply(first entries faces(n-1,C),i->exponents(i));
     sourceMonos:=apply(sourceL,k->myLcm(apply(positions(k,i->i!=0),j->I_j)));
     targetMonos:=apply(targetL,k->myLcm(apply(positions(k,i->i!=0),j->I_j)));
      getCoeff := (i,j) -> if (not member(-1,sourceL_j-targetL_i)) then
                             (-1)^(position(positions(sourceL_j,s->s!=0),t->sourceL_j_t!=targetL_i_t))
			   else 0_R;
      myFn := (i,j) -> (tempElt := sourceMonos_j / targetMonos_i;
	                if (liftable(tempElt,R)) then getCoeff(i,j)*lift(tempElt,R) else 0_R);
      retVal = map(R^(-apply(targetMonos, i -> degree i)), R^(-apply(sourceMonos, i -> degree i)), myFn);
    };
    retVal
     )


simplicialResolution=method();
simplicialResolution(MonomialIdeal, SimplicialComplex):=(I,C)-> (
     R:=ring(I);
     if (length(first entries faces(0,C))!=numgens I) then error "the number of vertices of the simplicial complex has to be the same as the number of generators of the ideal";
     chainComplex(apply((0..dim C),i->simplicialResolutionDifferential(i,I,C)))
     )

isResolution=method()
isResolution(ChainComplex,MonomialIdeal):=(C,I)->(
     return ((cokernel gens I==prune HH_0(C)) and ( all((min C+1,max C), i -> (prune HH_i(C) == 0))))
     )
-------------------
-- Local-Only Code
-------------------

lcmMon=method();
lcmMon(List):= (L) -> (
      len:=#(L_0);
      apply(len,i->max(apply(L,l->l_i)))  
)



--lcm function taken from package "ChainComplexExtras.m2"
myLcm = method()
myLcm(List):=(ringList)->(
   --- just a short method computing the lcm of the list of elements
   myList := apply(ringList, i -> ideal(i));
   (intersect myList)_0
)

admissibleSymbolsMonomial=method();
admissibleSymbolsMonomial(RingElement):=(m)->(
	  R:=ring m;
     lista:=subsets toList(0..maxVar(m)-1);
     mySubsets:=apply (lista, i->product(apply(i,j->R_j)));
     apply(mySubsets,i->(i,m))    
     )

admissibleSymbols=method();
admissibleSymbols(MonomialIdeal):=(M)->(
     flatten apply(first entries gens M,i->admissibleSymbolsMonomial(i))
     )

-- Given a monomial 'm' in the ideal I, returns the unique monomial 'u' in the minimal generating system of the monomial ideal, G(I),
-- satisfying m=u*m' with max(u)<=min(m'). The map from the set of monomials of I, M(I), to G(I) defined by this function is called
-- the canonical decomposition in [EK]
canonicalDecomp=method();
canonicalDecomp(RingElement,List):=(m,G)->( 
     vm:=flatten exponents m;  
     vG:=apply(G,g->flatten exponents g);
     n:=length vm-1;
     for j from 0 to length G-1 do(
	for i from 0 to n do(
	     if vG_j_i>vm_i then break;
	     if (vG_j_i<=vm_i and any(toList(i+1..n-1),k->vG_j_k>vm_k)) then break;
	     return G_j;  
	);       
     );	
     return("Error: this monomial does not belong to the ideal")  
)

--
--

maxVar=method();
maxVar(RingElement):=(m)->(
     max positions(first(exponents(m)),i->i!=0)
);

--The squarefree (SQ) versions of admissible symbols
admissibleSQSymbolsMonomial=method();
admissibleSQSymbolsMonomial(RingElement):=(m)->(
     R:=ring m;
     lista:=subsets positions((first exponents (m))_{0..maxVar(m)},i->i==0);
     mySubsets:=apply (lista, i->product(apply(i,j->R_j)));
     apply(mySubsets,i->(i,m))    
     )

admissibleSQSymbols=method();
admissibleSQSymbols(MonomialIdeal):=(M)->(
     flatten apply(first entries gens M,i->admissibleSQSymbolsMonomial(i))
     )

subcomplex=method();
subcomplex(RingElement, SimplicialComplex):=(M,C)->(
     R:=ring(C);
     L:=toList flatten apply(0..dim C,i->flatten entries faces(i,C));
     select(L,i->M//i!=0_R)
     )

labelledSubcomplex=method();
labelledSubcomplex(RingElement,SimplicialComplex,MonomialIdeal):=(M,C,I)->(
     R:=ring(I);
     L:=toList flatten apply(0..dim C,i->flatten entries faces(i,C));
     lista:=flatten apply(L,i->exponents(i));
     N:=positions(apply(lista,k->myLcm(apply(positions(k,i->i!=0),j->I_j))),i->M//i!=0_R);
     simplicialComplex(L_N)
     )
-------------------
-- Documentation
-------------------
beginDocumentation()

doc ///
   Key
       MonomialIdealResolutions
   Headline
       resolutions of some monomial ideals.
   Description
       Text
          This package includes multiple resolutions for monomial ideals. There are methods to compute the Eliahou-Kervaire resolution for stable monomial ideals, the Aramova-Herzog-Hibi resolution for squarefree stable monomial ideals (note that squarefree stable is different from "squarefree and stable") and it also contains methods for computing monomial resolutions supported on simplicial complexes.

           References:

	   [AHH] A.Aramova, J. Herzog and T. Hibi, "Squarefree lexsegment ideals"
	   Mat. Zeitschrift 228 (1998), 353-378
	   [BPS] D. Bayer, I. Peeva, B. Sturmfels, "Monomial resolutions", Math. Res. Lett. 5 (1998), 31-46
           [EK] S. Eliahou and M. Kervaire, "Minimal Resolutions of Some Monomial Ideals"
	    J. Algebra 129 (1990), 1-25.
///

doc ///
   Key
       isStable
		 (isStable, MonomialIdeal)
   Headline
       checks whether a monomial ideal is stable
   Usage
       isStable I
   Inputs
       I: MonomialIdeal
   Outputs
       B: Boolean
           returns true if and only if I is stable
   Description
       Text
           Determines if the monomial ideal I is stable. It uses the ordering of variables given by the ring of I. 
       Example
           R = QQ[x,y,z];
           I = monomialIdeal(x^3,x^2*y,x*y^2,y^3);
           isStable I
           J = monomialIdeal(x^3,x*y^2,y^3);
           isStable J
   SeeAlso
     MonomialIdeal
     isElement 
     isSQStable
///
doc ///
   Key
       isSQStable
		 (isSQStable, MonomialIdeal)
   Headline
       checks whether a monomial ideal is squarefree stable
   Usage
       isSQStable I
   Inputs
       I: MonomialIdeal
   Outputs
       B: Boolean
           returns true if and only if I is squarefree stable
   Description
       Text
           Determines if the monomial ideal I is squarefree stable. It uses the ordering of variables given by the ring of I. 
       Example
           R = QQ[x,y,z];
           I = monomialIdeal(x*y,x*z,y*z);
           isSQStable I
           J = monomialIdeal(x,y*z);
           isSQStable J
   SeeAlso
     MonomialIdeal
	  isElement 
	  isStable
///
doc ///
   Key
       isElement
		 (isElement, RingElement, MonomialIdeal)
   Headline
       check whether an element of the ring is in the monomial ideal or not
   Usage
       isElement(f,I)
   Inputs
       f: RingElement 
       I: MonomialIdeal
   Outputs
       B: Boolean
   Description
       Text
           This function check if f belongs to I
       Example
         R=QQ[x,y,z];
         f=x*y^2+x^3*y*z+z^2;
         g=x^2*y+x*y*z+x^3*z^3;
         I=monomialIdeal(x*y,x^3*z);
         isElement(f,I)
         isElement(g,I)
   SeeAlso
      isSubset
///

doc ///
   Key
       EK
       (EK,ZZ,MonomialIdeal)
   Headline
       constructs the n-th step of the Eliahou-Kervaire resolution
   Usage
       EK(n,I)
   Inputs
       n: ZZ
		 I: MonomialIdeal
   Outputs
       M: Matrix
   Description
       Text
          Returns a Matrix representing the map for the n-th step of the Eliahou-Kervaire resolution.
          WARNING: The function does not check if I is stable.
       Example
         R=QQ[x,y,z];
         I=monomialIdeal(x^2,x*y,y^2,y*z);
         EK(2,I)
        
   SeeAlso
      EKResolution
      isStable
///

doc ///
   Key
       EKResolution
		 (EKResolution,MonomialIdeal)
   Headline
       constructs the minimal free resolution given by S. Eliahou and M. Kervaire in [EK] for a stable monomial ideal. 
   Usage
       EKResolution I
   Inputs
       I: MonomialIdeal
   Outputs
       C: ChainComplex
   Description
       Text
         The Eliahou-Kervaire resolution is a minimal resolution for stable monomial ideals as shown in [EK]. This function computes degrees of modules and differencials in the minimal resolution of I according to the formulas in [EK].
         WARNING: The function does not check if I is stable. If it is not the result may not be a resolution!
       Example
         R=QQ[x,y,z];
         I=monomialIdeal(x^2,x*y,y^2,y*z);
         EKResolution(I)
   SeeAlso
      EK
      AHHResolution
      isStable
      MonomialIdeal
      ChainComplex
      isResolution
      res
///


doc ///
   Key
       AHH
      (AHH,ZZ,MonomialIdeal)
   
   Headline
       Constructs the n-th step of the minimal free resolution given by A.Aramova, J. Herzog and T. Hibi in [AHH] for a squarefree stable monomial ideal. 
   Usage
       AHH(n, I)
   Inputs
       n: ZZ
       I: MonomialIdeal
   Outputs
       C: Matrix
   Description
       Text
         Returns a matrix representing the map for the n-th step of the Aramova-Herzog-Hibi resolution.
         WARNING: The function does not check if I is squarefree stable.
       Example
         R=QQ[x,y,z];
         I=monomialIdeal(x*y,x*z,y*z);
         AHH(2,I)
   SeeAlso
      AHHResolution
      isSQStable
      MonomialIdeal      
///

doc ///
   Key
       AHHResolution
      (AHHResolution,MonomialIdeal)
   
   Headline
       Constructs the minimal free resolution given by A.Aramova, J. Herzog and T. Hibi in [AHH] for a squarefree stable monomial ideal. 
   Usage
       AHHResolution I
   Inputs
       I: MonomialIdeal
   Outputs
       C: ChainComplex
   Description
       Text
         The Aramova-Herzog-Hibi resolution is a minimal resolution for squarefree stable monomial ideals as shown in [AHH]. This function computes degrees of modules and differencials in the minimal resolution of I according to the formulas in [AHH].
         WARNING: The function does not check if I is squarefree stable. If it is not the result may not be a resolution!
       Example
         R=QQ[x,y,z];
         I=monomialIdeal(x*y,x*z,y*z);
         AHHResolution(I)
   SeeAlso
      AHH
      EKResolution
      isSQStable
      MonomialIdeal
      ChainComplex
      isResolution
      res
      
///

doc ///
   Key
     simplicialResolutionDifferential
     (simplicialResolutionDifferential,ZZ,MonomialIdeal,SimplicialComplex)
  Headline
    Constructs the matrix representing the n-th step of a chain complex supported on a simplicial complex SC labeled by the generators of the monomial ideal I.
  Usage
    simplicialResolutionDifferential(n, I, SC)
  Inputs
    n: ZZ
    I: MonomialIdeal
    SC: SimplicialComplex
  Outputs
    M: Matrix
  Description
    Text
      Returns a Matrix representing the map for the n-th step of the chain complex supported on a simplicial complex SC labeled by the generators of the monomial ideal I. This chain complex may or may not be a resolution of I.
    Example
      R=QQ[x,y,z];
      I=monomialIdeal(x*y,x*z,y*z);
      SC = simplicialComplex({x*y*z});
      simplicialResolutionDifferential(2,I,SC)
  SeeAlso
    simplicialResolution
    EKResolution
    taylorResolution
    MonomialIdeal
///

doc ///
  Key
    simplicialResolution
    (simplicialResolution, MonomialIdeal, SimplicialComplex)
  Headline
    Constructs a chain complex supported on a simplicial complex SC labeled by the generators of the monomial ideal I.
  Usage
    simplicialResolution(I, SC)
  Inputs
    I: MonomialIdeal
    SC: SimplicialComplex
  Outputs
    C: ChainComplex
  Description
    Text
      Constructs a chain complex supported on a simplicial complex SC labeled by the generators of the monomial ideal I. This chain complex may or may not be a resolution of I. The function checks if the number of generators of the ideal equals the number of vertices of the simplicial complex. 
      A condition for SC to be a resolution is given in [BPS].
      WARNING: The function does not check if the output is a resolution!
    Example
         R=QQ[x,y,z];
         I=monomialIdeal(x*y,x*z,y*z);
	 SC = simplicialComplex({x*y*z});
         simplicialResolution(I,SC)
  SeeAlso
      simplicialResolutionDifferential
      EKResolution
      taylorResolution
      MonomialIdeal
      ChainComplex
      isResolution
      res
///

doc ///
   Key
      isResolution
     (isResolution, ChainComplex, MonomialIdeal)
   Headline
       checks whether a ChainComplex is a resolution of a monomial ideal
   Usage
      isResolution(C,I)
   Inputs
     C: ChainComplex
     I: MonomialIdeal
   Outputs
     B: Boolean
         returns true if and only if C is a resolution of I
  Description
    Text
        Determines if the ChainComplex is a resolution of a monomial ideal I. It verifies if the complex is exact except at homological degree 0 where the homology is isomorphic to the ideal. 
	NOTE: It uses homology computations form the package ChainComplexExtras.
    Example
      R = QQ[x,y,z];
      I = monomialIdeal(x^3,x^2*y,x*y^2,y^3);
      isResolution(res I,I)
      isStable I
      isResolution(EKResolution I, I)
      J = monomialIdeal(x^3,x*y^2,y^3);
      isStable J
      isResolution(EKResolution J, J)
  SeeAlso
    MonomialIdeal
    isElement 
    isSQStable
///

-------------------
-- Tests
-------------------

-- Tests isElement
TEST ///
R = QQ[x,y,z];
I = monomialIdeal(x^3,x^2*y,x*y^2,y^3);
assert(isElement(x^3+x^6-x*y^3, I));
assert(isElement(y^3, I));
assert(not isElement(x^2, I));
assert(not isElement(x*y, I));
assert(not isElement(x*y*z, I));

J = monomialIdeal(x*y,x^3*z);
assert(not isElement(x*y^2+x^3*y*z+z^2, J));
assert(  isElement(x^2*y+x*y*z+x^3*z^3, J));
///


-- Tests isStable
TEST ///
R = QQ[x,y,z];
I = monomialIdeal(x^3,x^2*y,x*y^2,y^3);
assert(isStable I);
J = monomialIdeal(x^3,x*y^2,y^3);
assert(not isStable J);
assert(not isStable monomialIdeal z);
///


