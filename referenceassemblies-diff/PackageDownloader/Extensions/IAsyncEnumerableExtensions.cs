using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using NuGet.Protocol.Core.Types;

namespace PackageDownloader.Extensions
{
    internal static class IAsyncEnumerableExtensions
    {
        public static async IAsyncEnumerable<TResult> AsAsyncEnumerable<TResult>(this Task<IEnumerable<TResult>> @this)
        {
            IEnumerable<TResult> enumerable;
            getEnum:
            try
            {
                enumerable = await @this;
            }
            catch (FatalProtocolException e) when (e.InnerException is HttpRequestException { StatusCode: HttpStatusCode.InternalServerError })
            {
                goto getEnum;
            }

            foreach (var iteration in enumerable)
                yield return iteration;
        }
    }
}