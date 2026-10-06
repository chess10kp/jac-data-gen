import from "@jac/runtime" { Link, jacIsLoggedIn }
import from "lucide-react" { Leaf, Map, Package, Users, Calendar, ArrowRight, Heart, Zap, Shield, TrendingUp, ChevronDown }

def:pub LandingPage() -> JsxElement {
    logged_in: bool = jacIsLoggedIn();

    return (
        <div className="min-h-screen bg-white overflow-x-hidden">
            <div className="navbar anim-fade-in-down">
                <div className="navbar-inner">
                    <div className="navbar-logo">
                        <div className="navbar-logo-icon anim-scale-bounce delay-200">
                            <Leaf size={16} color="white" strokeWidth={2.5} />
                        </div>
                        <span className="text-primary anim-fade-in delay-300">{"Nourish"}</span>
                    </div>
                    <div className="hidden md:flex items-center gap-1 anim-fade-in delay-400">
                        <Link to="/map" className="nav-link animated-underline">{"Map"}</Link>
                        <Link to="/donations/feed" className="nav-link animated-underline">{"Donations"}</Link>
                        <Link to="/requests" className="nav-link animated-underline">{"Requests"}</Link>
                        <Link to="/events" className="nav-link animated-underline">{"Events"}</Link>
                    </div>
                    <div className="flex items-center gap-2 anim-fade-in delay-500">
                        {not logged_in and
                            <div className="flex items-center gap-2">
                                <Link to="/auth" className="btn btn-ghost btn-sm">{"Sign in"}</Link>
                                <Link to="/auth" className="btn btn-primary btn-sm btn-cinematic ripple-container">{"Get started"}</Link>
                            </div>
                        }
                        {logged_in and
                            <Link to="/dashboard/user" className="btn btn-primary btn-sm btn-cinematic">{"Dashboard"}</Link>
                        }
                    </div>
                </div>
            </div>

            <div className="hero relative overflow-hidden" style={{"minHeight": "100vh"}}>
                <div className="bg-animated-gradient absolute inset-0" />

                <div className="hero-particle" style={{"width": "300px", "height": "300px", "top": "10%", "left": "-5%", "animationDelay": "0s", "animationDuration": "10s"}} />
                <div className="hero-particle" style={{"width": "200px", "height": "200px", "top": "60%", "right": "-3%", "animationDelay": "3s", "animationDuration": "8s", "background": "rgba(245,158,11,0.1)"}} />
                <div className="hero-particle" style={{"width": "150px", "height": "150px", "top": "30%", "right": "15%", "animationDelay": "1.5s", "animationDuration": "12s"}} />
                <div className="hero-particle" style={{"width": "80px", "height": "80px", "bottom": "20%", "left": "20%", "animationDelay": "2s", "animationDuration": "7s", "background": "rgba(245,158,11,0.12)"}} />

                <div className="relative z-10 max-w-7xl mx-auto px-6 flex flex-col items-center justify-center text-center text-white" style={{"minHeight": "100vh", "paddingTop": "80px", "paddingBottom": "80px"}}>
                    <div className="anim-fade-in-down delay-200 inline-flex items-center gap-2 text-sm font-medium px-4 py-2 rounded-full mb-8 glass">
                        <Heart size={14} className="text-red-400" />
                        <span className="text-gray-200">{"Fighting food waste. Feeding communities."}</span>
                    </div>

                    <h1 className="anim-fade-in-up delay-300 text-6xl md:text-7xl font-extrabold tracking-tight mb-6 leading-tight">
                        {"Rescue Food."}
                        <br />
                        <span className="gradient-text-white">{"Feed People."}</span>
                    </h1>

                    <p className="anim-fade-in-up delay-400 text-xl text-gray-300 max-w-2xl mx-auto mb-10 leading-relaxed">
                        {"Nourish connects organizations with surplus food to shelters, food banks, and individuals in need. Real-time AI matching. Zero waste."}
                    </p>

                    <div className="anim-fade-in-up delay-500 flex flex-wrap justify-center gap-4 mb-16">
                        <Link to="/map" className="btn btn-primary btn-lg btn-cinematic ripple-container flex items-center gap-2 anim-pulse-glow">
                            <Map size={18} />
                            {"Find Food Near You"}
                        </Link>
                        <Link to="/requests/new" className="btn btn-lg glass text-white border-white/20 hover:bg-white/15 flex items-center gap-2">
                            {"Make a Request"}
                            <ArrowRight size={18} />
                        </Link>
                        <Link to="/auth" className="btn btn-lg flex items-center gap-2" style={{"background": "#F59E0B", "color": "white", "borderColor": "#F59E0B"}}>
                            {"Donate Food"}
                        </Link>
                    </div>

                    <div className="anim-fade-in-up delay-700 grid grid-cols-2 md:grid-cols-4 gap-6 w-full max-w-2xl">
                        <div className="text-center">
                            <div className="text-3xl font-extrabold neon-red">{"2,847"}</div>
                            <div className="text-xs text-gray-400 mt-1">{"Meals Saved"}</div>
                        </div>
                        <div className="text-center">
                            <div className="text-3xl font-extrabold" style={{"color": "#F59E0B", "textShadow": "0 0 20px rgba(245,158,11,0.4)"}}>{"1,203"}</div>
                            <div className="text-xs text-gray-400 mt-1">{"People Helped"}</div>
                        </div>
                        <div className="text-center">
                            <div className="text-3xl font-extrabold neon-red">{"4.2t"}</div>
                            <div className="text-xs text-gray-400 mt-1">{"Food Rescued"}</div>
                        </div>
                        <div className="text-center">
                            <div className="text-3xl font-extrabold" style={{"color": "#F59E0B", "textShadow": "0 0 20px rgba(245,158,11,0.4)"}}>{"47"}</div>
                            <div className="text-xs text-gray-400 mt-1">{"Partner Orgs"}</div>
                        </div>
                    </div>

                    <div className="anim-fade-in delay-1000 absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-1 text-gray-400">
                        <span className="text-xs">{"Scroll to explore"}</span>
                        <ChevronDown size={16} className="anim-float" />
                    </div>
                </div>
            </div>

            <div className="max-w-7xl mx-auto px-6 py-24">
                <div className="text-center mb-16 anim-fade-in-up">
                    <h2 className="text-4xl font-bold text-foreground mb-4">{"How Nourish Works"}</h2>
                    <p className="text-muted-foreground max-w-xl mx-auto text-lg">{"Three simple steps to connect surplus food with people who need it most."}</p>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-10">
                    <div className="text-center anim-fade-in-up delay-100 card-cinematic p-8 rounded-2xl border border-border">
                        <div className="w-20 h-20 bg-primary-light rounded-2xl flex items-center justify-center mx-auto mb-6 anim-float">
                            <Package size={32} className="text-primary" />
                        </div>
                        <h3 className="text-xl font-bold text-foreground mb-3">{"1. Post Available Food"}</h3>
                        <p className="text-muted-foreground">{"Organizations post surplus food with details, quantity, and pickup window."}</p>
                    </div>
                    <div className="text-center anim-fade-in-up delay-300 card-cinematic p-8 rounded-2xl border border-border">
                        <div className="w-20 h-20 rounded-2xl flex items-center justify-center mx-auto mb-6 anim-float delay-300" style={{"background": "#FEF3C7"}}>
                            <Zap size={32} className="text-secondary" />
                        </div>
                        <h3 className="text-xl font-bold text-foreground mb-3">{"2. AI Matches Instantly"}</h3>
                        <p className="text-muted-foreground">{"Our AI dispatcher matches donations to nearby shelters and urgent requests in real time."}</p>
                    </div>
                    <div className="text-center anim-fade-in-up delay-500 card-cinematic p-8 rounded-2xl border border-border">
                        <div className="w-20 h-20 rounded-2xl flex items-center justify-center mx-auto mb-6 anim-float delay-600" style={{"background": "#DCFCE7"}}>
                            <Heart size={32} className="text-success" />
                        </div>
                        <h3 className="text-xl font-bold text-foreground mb-3">{"3. Food Reaches People"}</h3>
                        <p className="text-muted-foreground">{"Volunteers pick up and deliver. Families get fed. Food waste is eliminated."}</p>
                    </div>
                </div>
            </div>

            <div className="py-20 relative overflow-hidden" style={{"background": "linear-gradient(135deg, #1F2937 0%, #111827 100%)"}}>
                <div className="hero-particle" style={{"width": "400px", "height": "400px", "top": "-20%", "right": "-10%", "animationDuration": "15s"}} />
                <div className="max-w-7xl mx-auto px-6 relative z-10">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                        <div className="anim-fade-in-left glass rounded-2xl p-8 text-white">
                            <div className="w-14 h-14 rounded-xl flex items-center justify-center mb-5" style={{"background": "rgba(220,38,38,0.2)"}}>
                                <Users size={26} className="text-red-400" />
                            </div>
                            <h3 className="text-2xl font-bold mb-3">{"I Need Food"}</h3>
                            <p className="text-gray-300 mb-6">{"Browse available donations near you, create a food request, or find upcoming distribution events."}</p>
                            <Link to="/map" className="btn btn-primary btn-cinematic ripple-container flex items-center gap-2 w-fit">
                                {"Find Food Near Me"}
                                <ArrowRight size={16} />
                            </Link>
                        </div>
                        <div className="anim-fade-in-right rounded-2xl p-8 text-white" style={{"background": "linear-gradient(135deg, rgba(245,158,11,0.15), rgba(245,158,11,0.05))", "border": "1px solid rgba(245,158,11,0.2)"}}>
                            <div className="w-14 h-14 rounded-xl flex items-center justify-center mb-5" style={{"background": "rgba(245,158,11,0.2)"}}>
                                <Package size={26} className="text-amber-400" />
                            </div>
                            <h3 className="text-2xl font-bold mb-3">{"I Have Food to Donate"}</h3>
                            <p className="text-gray-300 mb-6">{"Post surplus food, manage donations, view AI-powered insights, and track your community impact."}</p>
                            <Link to="/auth" className="btn btn-cinematic ripple-container flex items-center gap-2 w-fit" style={{"background": "#F59E0B", "color": "white", "borderColor": "#F59E0B"}}>
                                {"Start Donating"}
                                <ArrowRight size={16} />
                            </Link>
                        </div>
                    </div>
                </div>
            </div>

            <div className="max-w-7xl mx-auto px-6 py-20">
                <div className="anim-fade-in-up text-center mb-12">
                    <h2 className="text-3xl font-bold text-foreground mb-3">{"Trusted by Organizations"}</h2>
                    <p className="text-muted-foreground">{"Join the growing network of food rescue heroes."}</p>
                </div>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                    <div className="anim-scale-in delay-100 stat-cinematic card p-6 text-center">
                        <div className="text-4xl font-extrabold gradient-text-red mb-1">{"2,847"}</div>
                        <div className="text-sm text-muted-foreground">{"Meals Saved"}</div>
                    </div>
                    <div className="anim-scale-in delay-200 stat-cinematic card p-6 text-center">
                        <div className="text-4xl font-extrabold gradient-text-red mb-1">{"1,203"}</div>
                        <div className="text-sm text-muted-foreground">{"People Helped"}</div>
                    </div>
                    <div className="anim-scale-in delay-300 stat-cinematic card p-6 text-center">
                        <div className="text-4xl font-extrabold gradient-text-red mb-1">{"4.2t"}</div>
                        <div className="text-sm text-muted-foreground">{"Food Rescued"}</div>
                    </div>
                    <div className="anim-scale-in delay-400 stat-cinematic card p-6 text-center">
                        <div className="text-4xl font-extrabold gradient-text-red mb-1">{"47"}</div>
                        <div className="text-sm text-muted-foreground">{"Partner Orgs"}</div>
                    </div>
                </div>
            </div>

            <div className="bg-foreground text-white py-12">
                <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-row items-center justify-between gap-6">
                    <div className="anim-fade-in-left">
                        <div className="flex items-center gap-2 mb-2">
                            <div className="navbar-logo-icon"><Leaf size={14} color="white" /></div>
                            <span className="font-bold text-lg">{"Nourish"}</span>
                        </div>
                        <p className="text-gray-400 text-sm">{"Connecting surplus food with communities in need."}</p>
                    </div>
                    <div className="flex gap-6 text-sm text-gray-400 anim-fade-in-right">
                        <Link to="/map" className="hover:text-white transition-colors animated-underline">{"Map"}</Link>
                        <Link to="/donations/feed" className="hover:text-white transition-colors animated-underline">{"Donations"}</Link>
                        <Link to="/requests" className="hover:text-white transition-colors animated-underline">{"Requests"}</Link>
                        <Link to="/events" className="hover:text-white transition-colors animated-underline">{"Events"}</Link>
                    </div>
                </div>
            </div>


        </div>
    );
}
