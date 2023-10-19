using Xunit;
using Amazon.Lambda.Core;
using Amazon.Lambda.TestUtilities;

namespace MyLambdaFunctionAOT.Tests;

public class FunctionTest
{
    [Fact]
    public async Task TestToUpperFunction()
    {
        // Invoke the lambda function and confirm the string was upper cased.
        var context = new TestLambdaContext();
        var upperCase = await  Function.FunctionHandler(new Amazon.Lambda.APIGatewayEvents.APIGatewayHttpApiV2ProxyRequest(), context);

        Assert.Equal(200, upperCase.StatusCode);
    }
}