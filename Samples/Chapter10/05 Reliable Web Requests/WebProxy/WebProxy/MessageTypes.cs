﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:2.0.50727.42
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

// 
// This source code was auto-generated by xsd, Version=2.0.50727.42.
// 
namespace Microsoft.Samples.SqlServer {
    using System.Xml.Serialization;
    
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("xsd", "2.0.50727.42")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(Namespace = "http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema")]
    [System.Xml.Serialization.XmlRootAttribute("httpRequest", Namespace = "http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema", IsNullable = false)]
    public partial class httpRequestType {
        
        private headerType[] headersField;
        
        private byte[] bodyField;
        
        private string methodField;
        
        private string urlField;
        
        private string protocolVersionField;
        
        public httpRequestType() {
            this.methodField = "GET";
            this.protocolVersionField = "HTTP/1.1";
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlArrayAttribute(Form=System.Xml.Schema.XmlSchemaForm.Unqualified)]
        [System.Xml.Serialization.XmlArrayItemAttribute("header", Form=System.Xml.Schema.XmlSchemaForm.Unqualified, IsNullable=false)]
        public headerType[] headers {
            get {
                return this.headersField;
            }
            set {
                this.headersField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute(Form=System.Xml.Schema.XmlSchemaForm.Unqualified, DataType="base64Binary")]
        public byte[] body {
            get {
                return this.bodyField;
            }
            set {
                this.bodyField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        [System.ComponentModel.DefaultValueAttribute("GET")]
        public string method {
            get {
                return this.methodField;
            }
            set {
                this.methodField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute(DataType="anyURI")]
        public string url {
            get {
                return this.urlField;
            }
            set {
                this.urlField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        [System.ComponentModel.DefaultValueAttribute("HTTP/1.1")]
        public string protocolVersion {
            get {
                return this.protocolVersionField;
            }
            set {
                this.protocolVersionField = value;
            }
        }
    }
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("xsd", "2.0.50727.42")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(Namespace = "http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema")]
    public partial class headerType {
        
        private string nameField;
        
        private string valueField;
        
        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string name {
            get {
                return this.nameField;
            }
            set {
                this.nameField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string value {
            get {
                return this.valueField;
            }
            set {
                this.valueField = value;
            }
        }
    }
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("xsd", "2.0.50727.42")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(Namespace = "http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema")]
    [System.Xml.Serialization.XmlRootAttribute("httpResponse", Namespace = "http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema", IsNullable = false)]
    public partial class httpResponseType {
        
        private headerType[] headersField;
        
        private byte[] bodyField;
        
        private string protocolVersionField;
        
        private int statusCodeField;
        
        private string statusDescriptionField;
        
        /// <remarks/>
        [System.Xml.Serialization.XmlArrayAttribute(Form=System.Xml.Schema.XmlSchemaForm.Unqualified)]
        [System.Xml.Serialization.XmlArrayItemAttribute("header", Form=System.Xml.Schema.XmlSchemaForm.Unqualified, IsNullable=false)]
        public headerType[] headers {
            get {
                return this.headersField;
            }
            set {
                this.headersField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute(Form=System.Xml.Schema.XmlSchemaForm.Unqualified, DataType="base64Binary")]
        public byte[] body {
            get {
                return this.bodyField;
            }
            set {
                this.bodyField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string protocolVersion {
            get {
                return this.protocolVersionField;
            }
            set {
                this.protocolVersionField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public int statusCode {
            get {
                return this.statusCodeField;
            }
            set {
                this.statusCodeField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string statusDescription {
            get {
                return this.statusDescriptionField;
            }
            set {
                this.statusDescriptionField = value;
            }
        }
    }
}
