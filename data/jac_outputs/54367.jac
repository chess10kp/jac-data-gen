"""
     - Name: TempMin -Version: 1.0, -Time step: 1
     - Description:
                 * Title: Minimum temperature  calculation
                 * Author: STICS
                 * Reference: doi:http://dx.doi.org/10.1016/j.agrformet.2014.05.002
                 * Institution: INRA
                 * Abstract: recalculation of minimum temperature
     - inputs:
                 * name: Sdepth_cm
                               ** description : snow depth
                               ** inputtype : variable
                               ** variablecategory : state
                               ** datatype : DOUBLE
                               ** default : 0.0
                               ** min : 0.0
                               ** max : 500.0
                               ** unit : cm
                               ** uri :
                 * name: prof
                               ** description : snow cover threshold for snow insulation
                               ** inputtype : parameter
                               ** parametercategory : constant
                               ** datatype : DOUBLE
                               ** default : 0.0
                               ** min : 0.0
                               ** max : 1000
                               ** unit : cm
                               ** uri :
                 * name: tmin
                               ** description : current minimum air temperature
                               ** inputtype : variable
                               ** variablecategory : auxiliary
                               ** datatype : DOUBLE
                               ** default : 0.0
                               ** min : 0.0
                               ** max : 100.0
                               ** unit : degC
                               ** uri :
                 * name: tminseuil
                               ** description : minimum temperature when snow cover is higher than prof
                               ** inputtype : parameter
                               ** parametercategory : constant
                               ** datatype : DOUBLE
                               ** default : 0.0
                               ** min : 0.0
                               ** max : 5000.0
                               ** unit : degC
                               ** uri :
                 * name: tmaxseuil
                               ** description : maximum temperature when snow cover is higher than prof
                               ** inputtype : parameter
                               ** parametercategory : constant
                               ** datatype : DOUBLE
                               ** default : 0.0
                               ** min :
                               ** max :
                               ** unit : degC
                               ** uri :
     - outputs:
                 * name: tminrec
                               ** description : recalculated minimum temperature
                               ** variablecategory : state
                               ** datatype : DOUBLE
                               ** min : 0.0
                               ** max : 500.0
                               ** unit : degC
                               ** uri :
    """
def model_tempmin(
    Sdepth_cm: float = 0.0,
    prof: float = 0.0,
    tmin: float = 0.0,
    tminseuil: float = 0.0,
    tmaxseuil: float = 0.0
) -> float {
    tminrec = tmin;
    if Sdepth_cm > prof {
        if tmin < tminseuil {
            tminrec = tminseuil;
        } elif tmin > tmaxseuil {
            tminrec = tmaxseuil;
        }
    } elif Sdepth_cm > 0.0 {
        offset = (abs(tmin) as float) + tminseuil;
        tminrec = tminseuil - (1.0 - (Sdepth_cm / prof)) * offset;
    }
    return tminrec;
}