using System;
using System.Web;
using System.Web.Services;
using System.Web.Services.Protocols;

[WebService(Namespace = "http://www.csharp.at")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
public class Service : System.Web.Services.WebService
{
    public Service () 
    {
    }

    [WebMethod]
    public string HelloWorld() 
    {
        return "Hello World from our reliable web service written in C#, " + DateTime.Now.ToShortTimeString();
    }
}