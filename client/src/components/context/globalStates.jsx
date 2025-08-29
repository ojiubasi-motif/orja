/* eslint-disable react/prop-types */
import { createContext, useState } from "react";

export const GlobalStatesContext = createContext();
export const GlobalStatesProvider = ({ children }) => {
  const [toggleModal, setModal] = useState({show:false,action:null, data:null})
  const [toast, setToast] = useState({show:false, msg:null})

  
    return (
    <GlobalStatesContext.Provider value={{toggleModal,setModal,toast,setToast}}>
      {children}
    </GlobalStatesContext.Provider>
  );
};
