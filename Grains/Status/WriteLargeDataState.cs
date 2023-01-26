namespace Grains.Status
{
    [Serializable]
    public class ValidZipCodeState
    {
        public ValidZipCodeState() { }
        public ValidZipCodeState(string zipCode) => ValidZipCodes.Add(zipCode);
        public List<string> ValidZipCodes { get; private set; } = new();
    }
}

