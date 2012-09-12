using System.Data.SqlTypes;
using System.IO;
using Microsoft.SqlServer.Server;

namespace tSQLtTestUtilCLR
{
    [SqlUserDefinedType(Format.UserDefined, MaxByteSize = 5, IsFixedLength = true)]
    public class DataTypeNoEqual : INullable, IBinarySerialize
    {
        private int _i;

        public bool IsNull { get; private set; }

        public override string ToString()
        {
            return "<<DataTypeNoEqual>>";
        }

        public static DataTypeNoEqual Parse(SqlString s)
        {
            return new DataTypeNoEqual() { IsNull = (s.IsNull), _i = int.Parse(s.Value)};
        }

        public static DataTypeNoEqual Null
        {
            get { return new DataTypeNoEqual() {IsNull = true}; }
        }

        public void Read(BinaryReader r)
        {
            IsNull = r.ReadBoolean();
            _i = r.ReadInt32();
        }

        public void Write(BinaryWriter w)
        {
            w.Write(IsNull);
            w.Write(_i);
        }
    }
}
